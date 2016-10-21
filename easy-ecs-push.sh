#!/bin/bash


usage()
{
cat << EOF
usage: $0 options

Pushes a ECR repository image to an ECS cluster. Updates task definition with image along the way.

OPTIONS:
	ECS Opts: 
		
		-c        ECS Cluster
   		-s        ECS Service
   		-f        ECS Task Family

   	ECR Opts:
   		
   		-r        ECR respository URL 
   		-t        ECR respository image tag
   
EOF
}

ECS_CLUSTER=
ECS_SERVICE=
ECS_TASK_FAMILY=

ECR_REPO_URL=
ECR_IMAGE_TAG=

while getopts "c:s:f:r:t:" OPTION
do
	case $OPTION in
		h)
			usage
			exit 1
			;;
		c)
			ECS_CLUSTER=$OPTARG
			;;
		s)
			ECS_SERVICE=$OPTARG
			;;
		f)
			ECS_TASK_FAMILY=$OPTARG
			;;
		r)
			ECR_REPO_URL=$OPTARG
			;;
		t)
			ECR_IMAGE_TAG=$OPTARG
			;;
		?)
			usage
			exit 1
			;;
		
     esac
done


if [[ -z $ECS_CLUSTER ]]
then
	echo "Specify an ECS cluster"
	echo ""
	usage
	exit 1
fi

if [[ -z $ECS_SERVICE ]]
then
	echo "Specify an ECS service"
	echo ""
	usage
	exit 1
fi

if [[ -z $ECS_TASK_FAMILY ]]
then
	echo "Specify an ECS task family"
	echo ""
	usage
	exit 1
fi

if [[ -z $ECR_REPO_URL ]]
then
	echo "Specify an ECR respository URL"
	echo ""
	usage
	exit 1
fi

if [[ -z $ECR_IMAGE_TAG ]]
then
	echo "Specify an ECR image tag"
	echo ""
	usage
	exit 1
fi



echo ""
echo "Loading '$ECS_TASK_FAMILY' task definition..."

DEFINITION_JSON=`aws ecs describe-task-definition --task-definition=$ECS_TASK_FAMILY`


EDIT_TASK_DEFINITION_JSON=`echo $DEFINITION_JSON | python -c "import sys, json

j = json.load(sys.stdin)

for idx,v in enumerate(j['taskDefinition']['containerDefinitions']):
	if 'image' in v:
		if '$ECR_REPO_URL:' in v['image']:
			v['image'] = '$ECR_REPO_URL:$ECR_IMAGE_TAG'
			j['taskDefinition']['containerDefinitions'][idx] = v

print json.dumps(j['taskDefinition']['containerDefinitions']).replace('\r\n',' ')"`

echo ""
echo "Registering task definition for '$ECS_TASK_FAMILY'..."

NEW_TASK_DEFINITION_JSON=`aws ecs register-task-definition --family $ECS_TASK_FAMILY --container-definitions "$EDIT_TASK_DEFINITION_JSON"`

NEW_TASK_DEFINITION=`echo $NEW_TASK_DEFINITION_JSON | python -c "import sys, json

j = json.load(sys.stdin)

print j['taskDefinition']['family']+':'+str(j['taskDefinition']['revision'])"`


aws ecs update-service --cluster $ECS_CLUSTER --service $ECS_SERVICE --task-definition $NEW_TASK_DEFINITION > /dev/null

echo ""

echo "Waiting for service '$ECS_SERVICE' on cluster '$ECS_CLUSTER' to start..."
echo "   Will check every 15 seconds, max 40 checks"
echo "   Emits on failure, empty response on success"
echo ""
echo "   PS: If this fails (or is slow), double check your load balancers!!"

echo ""

aws ecs wait services-stable --cluster $ECS_CLUSTER --services $ECS_SERVICE
