FROM hashicorp/terraform:0.12.20

WORKDIR /tmp/certs
COPY main.tf /tmp/certs/main.tf

RUN terraform init

ENTRYPOINT ["terraform", "apply", "-auto-approve"]
