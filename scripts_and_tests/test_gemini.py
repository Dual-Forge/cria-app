import requests

url = "https://generativelanguage.googleapis.com/v1beta/models?key=AIzaSyDyrIC1C7dpVM0JrPLpo6F-iJJ7LJ7Lx_0"
response = requests.get(url)
print(response.status_code)
print(response.json())
