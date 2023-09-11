## Failure testing example pipeline ##

*This solution is suitable only for Yandex Cloud*
### Before begining ###

>**Check resource quotas** </br>
> Resource requirements are based on initial default quotas in an empty, newly created cloud

You will need

|Quota|Value|
|-----|-----|
|Number of cloud networks|2|
|Number of security groups|7|
|Number of all public IP addresses|2|
|Number of static public IP addresses|1|
|Number of subnets|7|
|Number of disks|8|
|Number of vCPUs for instances|23|
|Total RAM for instances|46 GB|
|Number of instances|8| 
|Total SSD capacity|150 GB|
|Total size of non-replicated SSDs|465 GB|
|Number of instance groups|3|

### Infrastructure preparation ###

1.  Delegate a DNS domain to Yandex Cloud. It could be either a 2nd level domain or a 3rd level domain.
    2nd level domain should be delegated through a domain registrar.
    3rd level domain can be delegated via your DNS hosting.
    You need to create in your DNS zone (e.g. example.com) two NS records like these:
    ```
    playground.example.com.           3600    IN      NS      ns1.yandexcloud.net.
    playground.example.com.           3600    IN      NS      ns2.yandexcloud.net.
    ```
1.  [Install Yandex Cloud CLI](https://cloud.yandex.ru/docs/cli/quickstart) and setup access to the cloud via
    ```
    yc init
    ```
1.  Create an empty cloud folder for experiments and get its `folder_id`.
1.  [Create new](https://cloud.yandex.ru/docs/managed-gitlab/quickstart) or use an exiting GitLab instance.
1.  In GitLab create a new empty project and get the project id. It could be found in the "Project overview" section of the Project page.
1.  [Create the project access token](https://docs.gitlab.com/ee/user/project/settings/project_access_tokens.html) with `Maintainer` role and `api` scope (it grants complete read and write access to the scoped project API).
1.  [Install terraform and setup access to your cloud](https://cloud.yandex.ru/docs/tutorials/infrastructure-management/terraform-quickstart) 
1.  Clone this repo, copy demo/failure-testing directory to a different place.
1.  Go to new location of failure-testing and get into `boostrap` subdirectory.
1.  Prepare terraform variables e.g. create in `boostrap` subdirectory terraform.tfvars file with the following content 
    ```
    folder_id             = "b1gxxxxxxxxxxx"                              # your folder_id here
    dns_domain            = "playground.example.com"                      # your domain here
    dns_hostnames         = ["test1"]                                     # subdomain name here
    gitlab_runner_enabled = true
    gitlab_url            = "https://xxxxxxx.gitlab.yandexcloud.net"      # your GitLab instance URL
    gitlab_project_id     = "0000"                                        # your GitLab project id
    gitlab_username       = "your-username"                               # your GitLab username
    gitlab_access_token   = "glpat-xxxxxxxxxx"                            # your GitLab project access token
    ```
1.  Prepare environment:
    ```
    export YC_TOKEN=$(yc iam create-token)
    ``` 
1.  Run 
    ```
    terraform init
    terraform apply
    ``` 
    check the plan and confirm the creation. This step will prepare the initial infrastructure - DNS, Container Registry, gitlab-runner. It will also prepare the repo by adding necessary CI/CD variables and registering gitlab-runner.

### Test running ###
1.  Follow to root directory of the new repo.
1.  Set the remote tracked repository by executing (don't forget to set URL of your repo)
    ```
    git remote add origin git@xxxxxxx.gitlab.yandexcloud.net:new/repo/location.git
    ```
1.  Put the code to GitLab 
    ```
    git add .
    git commit -m "Initial commit"
    git push --set-upstream origin master
    ```
1.  Go to `build` section on the GitLab project page and watch the pipeline.
1.  Check the result in the job log and on the ALB monitoring page.
1.  When pipeline succeeded, got to build/pipelines section on GitLab project page, click `Run pipeline` button, set variable `TF_VAR_zones` to `[ "ru-central1-a", "ru-central1-b" ]` and click `Run pipeline` button.
1.  Go to `build` section on the project page and watch the pipeline again.
1.  When you finished check the result - it must be much better than the result of the previous test.
1.  Go to build/pipelines page and run the `clean` step for resources releasing.

### Resources releasing ###
1.  Be sure that the clean step of the pipeline was done completely
1.  Open the Yandex Cloud web console, go to the Container Registry in testing folder and remove all images from the container registry.
1.  Go to bootstrap directory and run `terraform destroy`, check the plan and confirm the deletion
