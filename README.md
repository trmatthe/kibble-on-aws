# tech.kibble.cloud on AWS

This repository hosts the Terraform HCL to build an AWS-hosted replacement for my current technical writing 
site, [https://kibble.cloud/tech](https://kibble.cloud/tech)

It uses S3 for storage, ACM for TLS, and CloudFront for distribution.

I've seen a few articles on doing this, but the Terraform code here is written to comply with the newer AWS
provider which I've not seen elsewhere.

The second stage of this project will show how to use Terraform to configure the github repo with GH Actions
that will automatically update the site when new content is committed.

At the moment the write-up is at [https://kibble.cloud/tech/](https://kibble.cloud/tech/) but once complete
the site will move. To this :)

I am always happy to get feedback.

