import requests

url = "https://generativelanguage.googleapis.com/v1beta/models?key=AIzaSyAZHuiInkMzYfMTXKhrDe0J0GY0WVe2erE"
response = requests.get(url)
print(response.status_code)
print(response.json())
