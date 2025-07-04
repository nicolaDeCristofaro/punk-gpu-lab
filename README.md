# private-and-secure-ai-ready-development-workspace
A private, secure, gpu-ready and cloud-based development workspace powered by AWS EC2 and System Manager.

Console → Service Quotas → Amazon EC2 Spot Instances → Request quota increase > All G and VT Spot Instance Requests (for the instance type used here at least 4 vCPUs) Until approved, launches will fail.

VS Code extensions needed
- AWS Toolkit >= 3.39.0
- Requires remote-ssh (which requires ssh on your local desktop)

1. AWS Toolkit login
- select the extension on the left
- select connection (if you previously logged in with a specific profile) - to deep dive on this
- expand EC2 and select the EC2 you want to connect to
- click on AWS: Connect VSCode to EC2 instance
- it will open a new VSCode window inside the EC2

\*Supports EC2 instances running Linux or macOS (not Windows, currently).
\*Your local desktop can be Linux/macOS (not Windows, currently).
