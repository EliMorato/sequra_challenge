"""Pipeline Configuration"""

from pydantic import BaseModel, Field
from os.path import expandvars
from pathlib import Path
import yaml
import logging

logger = logging.getLogger(__name__)
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s:%(levelname)s: %(message)s",
    datefmt="%Y-%m-%d %I:%M:%S%p",
)
CONFIG_PATH = Path(__file__).parent.parent / "conf/pipeline.yaml"

class AWSConfig(BaseModel):
    aws_access_key_id: str = Field(..., description="AWS access key ID")
    aws_secret_access_key: str = Field(..., description="AWS secret access key")
    aws_role_arn: str = Field(..., description="AWS role ARN")


class StorageConfig(BaseModel):
    bucket_name: str = Field(..., description="S3 bucket name")
    sm_secret_name: str = Field(..., description="Secrets Manager secret name containing Redshift connection details")


class PipelineConfig(BaseModel):
    aws: AWSConfig
    storage: StorageConfig


def load_config(path: Path) -> PipelineConfig:
    """Load the manifest from the path"""
    try:
        with path.open() as config_file:
            raw_config = config_file.read()
            expanded = expandvars(raw_config)
        config = yaml.safe_load(expanded)
        return PipelineConfig(**config)
    except yaml.error.YAMLError as exc:
        logging.error(f"Cannot load manifest in [{path}] due to [{exc}]")
        raise exc

CONFIG = load_config(CONFIG_PATH)
