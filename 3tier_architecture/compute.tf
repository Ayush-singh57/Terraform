# APPLICATION LOAD BALANCER (Public)
resource "aws_lb" "app_alb" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1a.id, aws_subnet.public_1b.id] 
}

resource "aws_lb_target_group" "app_tg" {
  name     = "app-target-group"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# LAUNCH TEMPLATE & AUTO SCALING GROUP (Private)
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_launch_template" "app_lt" {
  name_prefix   = "app-server-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y python3 python3-pip

              pip3 install Flask PyMySQL

              mkdir -p /home/ec2-user/app/templates
              cd /home/ec2-user/app

              # 1. Inject Terraform variables directly into Python (Bulletproof)
              cat << 'EOT' > app.py
              from flask import Flask, request, jsonify, render_template
              import pymysql

              app = Flask(__name__)

              def get_db():
                  return pymysql.connect(
                      host="${aws_db_instance.app_db.address}",
                      user="${var.db_username}",
                      password="${var.db_password}",
                      database="appdata",
                      cursorclass=pymysql.cursors.DictCursor,
                      connect_timeout=5
                  )

              # 2. Lazy Initialization: Creates the table ONLY when requested
              def init_db():
                  db = get_db()
                  with db.cursor() as c: 
                      c.execute("CREATE TABLE IF NOT EXISTS messages (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(255), message TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)")
                  db.commit()
                  db.close()

              @app.route('/')
              def index(): 
                  return render_template('index.html')

              @app.route('/api/submit', methods=['POST'])
              def submit():
                  try:
                      init_db() # Ensures table exists before inserting
                      data = request.json
                      db = get_db()
                      with db.cursor() as c: 
                          c.execute("INSERT INTO messages (name, message) VALUES (%s, %s)", (data.get('name'), data.get('message')))
                      db.commit()
                      db.close()
                      return jsonify({'success': True})
                  except Exception as e:
                      return jsonify({'error': str(e)}), 500

              @app.route('/api/recent', methods=['GET'])
              def recent():
                  try:
                      init_db() # Ensures table exists before fetching
                      db = get_db()
                      with db.cursor() as c: 
                          c.execute("SELECT name, message FROM messages ORDER BY created_at DESC LIMIT 5")
                      res = c.fetchall()
                      db.close()
                      return jsonify(res)
                  except Exception as e:
                      # 3. If it fails, print the EXACT Database Error to the screen!
                      return jsonify([{'name': 'SYSTEM DB ERROR', 'message': str(e)}])

              if __name__ == '__main__': 
                  app.run(host='0.0.0.0', port=5000)
              EOT

              # 4. Write Frontend
              cat << 'EOT' > templates/index.html
              <!DOCTYPE html>
              <html lang="en">
              <head>
                  <meta charset="UTF-8">
                  <meta name="viewport" content="width=device-width, initial-scale=1.0">
                  <title>3-Tier Architecture Final</title>
                  <style>
                      body { font-family: system-ui, sans-serif; max-width: 600px; margin: 2rem auto; padding: 1rem; color: #333; }
                      .form-group { display: flex; flex-direction: column; gap: 1rem; margin-bottom: 2rem; background: #f8f9fa; padding: 1.5rem; border-radius: 8px; border: 1px solid #dee2e6; }
                      input, textarea { padding: 0.75rem; font-size: 1rem; border: 1px solid #ccc; border-radius: 4px; }
                      button { padding: 0.75rem; background: #28a745; color: white; border: none; border-radius: 4px; cursor: pointer; font-size: 1rem; font-weight: bold; }
                      .fetch-btn { background: #007bff; margin-bottom: 1rem; width: 100%; }
                      .fetch-btn:hover { background: #0056b3; }
                      .data-card { background: #e9ecef; padding: 1rem; margin-bottom: 0.75rem; border-radius: 6px; border-left: 4px solid #007bff; }
                  </style>
              </head>
              <body>
                  <h2>Submit Data to RDS</h2>
                  <div class="form-group">
                      <input id="name" placeholder="Enter your name" required>
                      <textarea id="msg" rows="3" placeholder="Enter your message" required></textarea>
                      <button onclick="submitData()" id="saveBtn">Save to Database</button>
                  </div>
                  
                  <h2>Recent Database Records</h2>
                  <button class="fetch-btn" onclick="loadData()">Fetch Recent Records</button>
                  <div id="data"></div>
                  
                  <script>
                      async function submitData() {
                          const name = document.getElementById('name').value;
                          const message = document.getElementById('msg').value;
                          const btn = document.getElementById('saveBtn');
                          
                          btn.textContent = 'Saving...';
                          
                          await fetch('/api/submit', { 
                              method: 'POST', headers: { 'Content-Type': 'application/json' }, 
                              body: JSON.stringify({ name, message }) 
                          });
                          
                          document.getElementById('name').value = '';
                          document.getElementById('msg').value = '';
                          btn.textContent = 'Save to Database';
                          
                          alert('Data saved successfully to AWS RDS!'); 
                      }
                      
                      async function loadData() {
                          const container = document.getElementById('data');
                          container.innerHTML = 'Fetching securely from RDS...';
                          try {
                              let r = await fetch('/api/recent'); 
                              let d = await r.json();
                              if(d.length === 0) { container.innerHTML = '<p>No records found.</p>'; return; }
                              container.innerHTML = d.map(x => `<div class="data-card"><strong>`+x.name+`</strong><br>`+x.message+`</div>`).join('');
                          } catch(e) { container.innerHTML = 'Critical Server Error.'; }
                      }
                  </script>
              </body>
              </html>
              EOT

              nohup python3 app.py > app.log 2>&1 &
              EOF
  )
}

resource "aws_autoscaling_group" "app_asg" {
  name                = "app-autoscaling-group"
  vpc_zone_identifier = [aws_subnet.private_app_1a.id, aws_subnet.private_app_1b.id]
  target_group_arns   = [aws_lb_target_group.app_tg.arn]
  
  desired_capacity    = 2
  min_size            = 2
  max_size            = 4

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }
}