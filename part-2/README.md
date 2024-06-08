# Orchestration and Container Management with Kubernetes

## Deployment
In order to deploy a Kubernetes cluster containing an orchestrator (for example, Airflow) and the ingestion pipeline, I would do the following:
- Provision an EKS cluster using Terraform
- Install ArgoCD on the cluster
- Set up syncronization for the GitHub repository containing the Kubernetes manifest files with ArgoCD
- Install Airflow on EKS via Helm setting up an external database for the Airflow metastore, like AWS RDS, and disabling the default Postgres one
- Set up syncronization with the GitHub repository storing the DAGs code


## Monitoring
In order to be able to monitor my Kubernetes cluster, I would do the following:
- Install Prometheus in the Kubernetes cluster by using Helm chart
- The previous step should install Grafana as part of the Prometheus stack
- To collect Prometheus metrics from the cluster I'd use CloudWatch agent
