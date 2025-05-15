FROM public.ecr.aws/lambda/python:3.11

WORKDIR /app

RUN yum update -y && yum install zip -y

ENTRYPOINT pip install -r requirements.txt -t ./ && zip -r code.zip ./
