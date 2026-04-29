resource "aws_s3_bucket" "demo_bucket" {
  bucket = "ayush-demo-bucket-987654321" 
}

resource "aws_s3_object" "text_upload" {
  bucket = aws_s3_bucket.demo_bucket.id
  key    = "upload_cloud.txt" 
  source = "cloud.txt" 

}