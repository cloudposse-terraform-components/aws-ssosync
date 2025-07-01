import os
import subprocess

def lambda_handler(event, context):
    creds = os.environ.get("SSOSYNC_GOOGLE_CREDS_JSON")
    if not creds:
        print("SSOSYNC_GOOGLE_CREDS_JSON environment variable is not set.")
        raise Exception("SSOSYNC_GOOGLE_CREDS_JSON environment variable is not set.")

    print("Writing Google credentials to /tmp/credentials.json")
    with open("/tmp/credentials.json", "w") as f:
        f.write(creds)

    print("Executing ssosync command...")
    result = subprocess.run(["./ssosync"], capture_output=True, text=True)
    print(result.stdout)
    print(result.stderr)
    print(f"ssosync exited with code {result.returncode}")
    if result.returncode != 0:
        raise Exception(f"ssosync exited with code {result.returncode}")
    return {"status": "success"}
