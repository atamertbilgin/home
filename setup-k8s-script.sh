kubectl create secret docker-registry regcred \
    --docker-server=611289949201.dkr.ecr.us-east-1.amazonaws.com \
    --docker-username=AWS \
    --docker-password=$(aws ecr get-login-password --region us-east-1) \
    --docker-email=atamertbilgin@gmail.com
