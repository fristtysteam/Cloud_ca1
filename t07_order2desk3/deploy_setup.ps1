#!/usr/bin/env pwsh
# Order2Desk stack
# Peadar Grant

$StackName = "order2desk"
$MainStack = "order2desk"
$DeployStack = "${StackName}deploy"


## CREATING ZIP FILE

Write-Host 'creating code zip file... ' -NoNewLine
if ( $IsMacOs ) {
    # deal with permission bits set on Mac 
    # execute bit needs to be set (prior experience)
    chmod +x router.py common.py
    # need to use native ZIP command to respect permissions
    zip code.zip router.py common.py
}
else {
    # way to do this in PowerShell
    Compress-Archive -Force -DestinationPath code.zip -Path router.py,common.py
}
Write-Host 'ok' -ForegroundColor Green


## COPYING LAMBDA CODE TO AWS

Write-Host 'creating deploy stack' -NoNewLine
aws cloudformation create-stack --stack-name $DeployStack --template-body file://deploy_template.yml
Write-Host 'done' -ForegroundColor Green

Write-Host 'waiting for deploy stack to create...' -NoNewLine
aws cloudformation wait stack-create-complete --stack-name $DeployStack
Write-Host 'ok' -ForegroundColor Green

Write-Host 'copying to deploy bucket...' -NoNewLine
$DeployBucketName=((aws cloudformation describe-stacks --stack $DeployStack | ConvertFrom-Json).Stacks[0].Outputs | Where-Object OutputKey -eq DeployBucketName)[0].OutputValue
aws s3 cp code.zip s3://$DeployBucketName/code.zip
Write-Host 'ok' -ForegroundColor Green


Write-Host 'deploy stack is ready' -ForegroundColor Green
