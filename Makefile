terraform-init:
	cd terraform-eks && terraform init && cd -

terraform-plan:
	cd terraform-eks && \
	terraform plan && \
	cd -

terraform-apply:
	cd terraform-eks && \
	terraform apply && \
	cd -

terraform-destroy:
	cd terraform-eks && \
	terraform destroy && \
	cd -