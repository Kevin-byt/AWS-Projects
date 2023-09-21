# README: Hosting a Static Website on AWS S3

Welcome to the quick guide on how to host a static website on AWS S3 (Simple Storage Service). This README provides a summary of the steps outlined in the [full article](https://medium.com/@kevinkiruri/hosting-a-static-website-on-aws-s3-35f49dd1c5e6), authored by [Kevin Kiruri](https://www.linkedin.com/in/kevin-kiruri/).

## :rocket: Introduction

If you need to host a static website inexpensively, AWS S3 offers an easy, fast, and cost-effective solution. With AWS S3, you only pay for the storage you use, and you can even get up to 5GB of storage free of charge for a year within the AWS Free Tier.

## :scroll: Step-by-Step Guide

Follow these steps to host your static website on AWS S3:

1. **Access AWS Console**
   
   Go to your AWS console and search for "S3" in the search bar, then select "S3" when it appears.

2. **Create a Bucket**

   - Click on "Create bucket."
   - Provide a unique "Bucket name" for your website.

3. **Configure Bucket Settings**

   - Unselect "Block all public access" to allow internet users to access your website.
   - Click on "Create bucket" at the bottom.

4. **Select Your Bucket**

   Once created, select your bucket from the list.

5. **Configure Static Web Hosting**

   - Under the "Properties" tab, scroll down to "Static web hosting" and click on "Edit."
   - Click on "Enable" and select "Host a static website." Choose the default home page (index document) for your site.

6. **Set Up Error Handling (Optional)**

   - Enter the names of the index document and error document (if needed), then click "Save changes."

7. **Endpoint Creation**

   When "Static website hosting" is enabled, the bucket endpoint is created.

8. **Bucket Policy for File Access**

   - Create a bucket policy to enable access to the files.
   - Navigate to the "Permissions" tab and under the "Bucket policy" section, enter the provided policy, ensuring to change the Resource to your bucket's ARN followed by "/*".

9. **Upload Your Website**

   Create and upload your website files, including the "index.html" file as specified in step 8.

10. **Final Configuration**

    - Navigate to the "Properties" tab and load the bucket's endpoint. The "index.html" file will serve as the home page.
    - In case of an error (e.g., the index file is not available), the "error.html" page will be returned at the endpoint.

## :page_with_curl: Sample Website Pages

The article includes sample website pages for your reference:

- **index.html**: A basic static web page with AWS S3-themed content.
- **error.html**: A custom error page (404) for handling missing files.

## :tada: Conclusion

With these steps, you can easily host your static website on AWS S3, benefiting from its simplicity, speed, and cost-effectiveness. Have fun hosting your website!

For more details and a complete walkthrough, please refer to the original article: [Hosting a static website on AWS S3](https://medium.com/@kevinkiruri/hosting-a-static-website-on-aws-s3-35f49dd1c5e6).

---

*Author: [Kevin Kiruri](https://www.linkedin.com/in/kevin-kiruri/)*