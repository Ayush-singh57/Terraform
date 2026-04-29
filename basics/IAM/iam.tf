resource "aws_iam_user" "simple_user" {
  name = "basic_user"
}

resource "aws_iam_user_login_profile" "simple_login" {
  user = aws_iam_user.simple_user.name
}

# 3. S3 FULL ACCESS
resource "aws_iam_user_policy_attachment" "s3_access" {
  user       = aws_iam_user.simple_user.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# 4. EC2 READ ONLY
resource "aws_iam_user_policy_attachment" "ec2_read" {
  user       = aws_iam_user.simple_user.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

output "user_password" {
  value     = aws_iam_user_login_profile.simple_login.password
  sensitive = true
}