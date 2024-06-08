import json
import pandas as pd
import redshift_connector as rc
import logging
import boto3
from config import CONFIG

logger = logging.getLogger(__name__)
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s:%(levelname)s: %(message)s",
    datefmt="%Y-%m-%d %I:%M:%S%p",
)

URL = "https://api.spacexdata.com/v5/launches"
pd.options.mode.chained_assignment = None


class JSONLoadingError(Exception):
    """Exception raised for errors in the JSON data load."""


def read_json_from_url(url: str) -> pd.DataFrame:
    """Read JSON data into a Pandas DataFrame given a URL"""
    try:
        df = pd.read_json(url)
        return df
    except Exception as e:
        raise JSONLoadingError(f"Input raw data failed to load from URL {url}. {e}")


def extract_core_information(df: pd.DataFrame) -> pd.DataFrame:
    """Extract core data from DF and keep only relevant columns"""
    # Not importing net, tbd since they all had the same value
    df_select = df[['id', 'date_utc', 'date_precision', 'upcoming', 'cores', 'window', 'rocket', 'success', 'flight_number', 'name']]
   
    # Extract core information
    df_select.loc[:, 'core_ids'] = df_select['cores'].apply(lambda x: [d.get('core') for d in x])
    core_series = df_select.set_index('id')['core_ids'].explode()
    df_exploded_cores = pd.DataFrame(core_series.tolist(), index=core_series.index, columns=['core_id']).reset_index()
    
    # Join core ids with initial selection and drop columns
    df_joined = df_select.merge(df_exploded_cores, on='id', how='left').drop(columns=['core_ids', 'cores'])
    df_joined['success'] = df.success.replace({0:False, 1:True})
    return df_joined


def get_sm_credentials(secret_name) -> str:
    """Retrieve credentials from AWS Secrets Manager given a secret_name"""
    client = boto3.client(
        "secretsmanager",
        aws_access_key_id=CONFIG.aws.aws_access_key_id,
        aws_secret_access_key=CONFIG.aws.aws_secret_access_key,
    )
    response = client.get_secret_value(SecretId=secret_name)
    if "SecretString" not in response:
        raise Exception("Slack secret not found")

    secret_value = response["SecretString"]
    return json.loads(secret_value)


def load_data_into_redshift(
    schema_name: str, 
    table_name: str
):
    """ 
    Load data from the provided S3 bucket to the Redshift table.
    The Redshift table will be created if it doesn't exist already.
    """
    load_statements = []
    load_statements.append(f"""
    CREATE TABLE IF NOT EXISTS {schema_name}.{table_name}_tmp (
        id VARCHAR(256) NOT NULL ENCODE LZO,
        date_utc TIMESTAMPTZ NULL ENCODE AZ64,
        date_precision VARCHAR(256) NOT NULL ENCODE LZO,
        upcoming BOOLEAN NULL,
        window	DECIMAL(10,2) NULL,
        rocket VARCHAR(256) NULL,
        success	BOOLEAN NULL,
        flight_number BIGINT NULL,
        name VARCHAR(256) NULL,
        core_id VARCHAR(256) NULL ENCODE LZO 
    )
    DISTSTYLE ALL;
    """)
    load_statements.append(f"""
    COPY {schema_name}.{table_name}_tmp from '{CONFIG.storage.bucket_name}'
    CREDENTIALS 'aws_iam_role={CONFIG.aws.aws_role_arn}'
    CSV
    EMPTYASNULL
    TIMEFORMAT 'YYYY-MM-DDTHH:MI:SS.000Z'
    IGNOREHEADER 1;
    """)
    load_statements.append(f"DROP TABLE IF EXISTS {schema_name}.{table_name};")
    load_statements.append(f"""
    ALTER TABLE {schema_name}.{table_name}_tmp RENAME TO {table_name};
    """)

    redshift = get_sm_credentials(CONFIG.storage.sm_secret_name)
    conn = rc.connect(
            host=redshift["HOST"],
            port=redshift["PORT"],
            database=redshift["DATABASE"],
            user=redshift["USER"],
            password=redshift["PASSWORD"],
    )
    with conn.cursor() as cursor:
        cursor.execute("begin;")
        try:
            for st in load_statements:
                logger.info(f"Executing {st}")
                cursor.execute(st)
            cursor.execute("commit;")
        except Exception as e:
            logging.error(f"Redshift data load failed. {e}")        
            cursor.execute("commit;")

def main():
    df = read_json_from_url(URL)
    final_df = extract_core_information(df)
    # Load CSV to S3
    final_df.to_csv(
        f"{CONFIG.storage.bucket_name}data.csv", 
        index=False,    
        storage_options={
            "key": CONFIG.aws.aws_access_key_id,
            "secret": CONFIG.aws.aws_secret_access_key,
        })
    # Load S3 data to Redshift
    load_data_into_redshift("public", "launches")

if __name__ == '__main__':
    main()