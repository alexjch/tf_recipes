
## Testing lambda locally

[More info](https://hub.docker.com/r/amazon/aws-lambda-python)

```bash
export S3_BUCKET=...
export AWS_KEY=...
export AWS_SECRET=...
podman run -it --privileged -d --env "S3_BUCKET=${S3_BUCKET}" --env "AWS_ACCESS_KEY_ID=${AWS_KEY}$" --env "AWS_SECRET_ACCESS_KEY=${AWS_SECRET}" -p 9000:8080 -v ./function:/var/task public.ecr.aws/lambda/python:3.14.2025.12.11.15 lambda.handler

curl -vv -XPOST "http://localhost:9000/2015-03-31/functions/function/invocations" -d '{"payload":"hello world!"}'

...

{"statusCode": 200, "body": "{\"message\": \"Data saved successfully\", \"filename\": \"20251212/1765575705-23e63a95-33af-4252-99a9-0277822b3f9b\"}"}
```
