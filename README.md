# ha_app_test
Tf code to create ELB, Auto Scaling Groups etc


`terraform init -backed-config="bucket=${bucket-name}" -backed-config="key=test/ha_app_test/terraform.tfstate $(ROLE) -var this_env=$(AWS_ENV) -var-file="var-file.$(AWS_ENV)"`
