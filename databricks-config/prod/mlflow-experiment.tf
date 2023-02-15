resource "databricks_mlflow_experiment" "experiment" {
  name        = "${local.mlflow_experiment_parent_dir}/${local.env_prefix}srram-db-mlops-demo-experiment"
  description = "MLflow Experiment used to track runs for srram-db-mlops-demo project."
}
