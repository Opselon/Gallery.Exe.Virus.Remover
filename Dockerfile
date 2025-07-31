# Use an official Python runtime as a parent image for Windows
FROM python:3.10-windowsservercore

# Set the working directory in the container
WORKDIR /app

# Set the default shell to PowerShell
SHELL ["powershell", "-Command"]

# Copy the requirements file and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application's source code
COPY . .

# Set the entrypoint to run the application
ENTRYPOINT ["python", "-m", "gallery_lock"]
