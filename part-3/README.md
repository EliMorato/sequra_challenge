# ETL Pipeline
In the `sequra_challenge/part-3` we can find a script to extract, transform and load the SpaceX data from the SpaceX URL to the `public.launches` table in Redshift.

### Folder structure
    .
    ├── part-3
    │   ├── conf                  # Configuration folder
    │   │    └── pipeline.yaml    # YAML file with the pipeline configuration
    │   ├── sequra_challenge      # Project folder
    │   │    └── main.py          # Main script with the ETL logic
    │   ├── poetry.lock           # Poetry lock of the package dependencies
    │   ├── pyproject.toml        # Poertry project and dependencies definition
    │   └── README.md
    └── ...

## ETL execution
In order to execute this ETL, you need to create a secret in AWS Secrets Manager storing your Redshift credentials (HOST, PORT, DATABASE, USER, PASSWORD). You'll also need access to an S3 bucket and to set the bucket and the secret's name in `sequra_challenge/part-3/conf/pipeline.yaml`. 

Finally, provide the following information and execute:
```sh
export AWS_REGION=<region>
export AWS_ACCESS_KEY_ID=<access-key-id>
export AWS_SECRET_ACCESS_KEY=<secret-access-key>
export AWS_ROLE_ARN=<role-arn>
poetry run python sequra_challenge/main.py
```
If we run this process in a machine with the right roles, it will pick up the AWS configuration automatically.

## Schedule and monitoring
For the **scheduling** of this pipeline, I'd create an Airflow DAG and define the parameter `schedule_interval = @daily` since the volume of data is quite low and there's no specific time where the refresh has been requested, so every day at midnight would be a good option (plus, after working hours are the best time to execute data pipelines).

For the **monitoring**, I'd add Slack/email alerts to be send in case of a pipeline failure - with failure details - and another alert message in case of the pipeline finishing successfully - this can be set up in Airflow using sensors for the tasks and `failure_callback`. If a more thorough monitoring is needed, I'd propose sending logs to Datadog and creating alerts there that can also send Slack/email in case of the alert being triggered, but I don't think it's necessary in this case given it's a very small pipeline at the moment.

## Comments
As a good practice, I'd typically include a `/tests` folder in the project with tests covering as much code as possible and including unit, integration and end-to-end tests if applicable. 

I'd also include CI/CD workflows using CircleCI or GitHub Actions to execute the tests after a PR is created and block any merges unless critical checks pass, plus some worklows to deploy the merged code if needed (S3 sync, application build, etc).
