FROM hashicorp/terraform:0.13.5

WORKDIR /tmp/certs
COPY main.tf /tmp/certs/main.tf

RUN terraform init

ENTRYPOINT ["terraform", "apply", "-auto-approve"]
