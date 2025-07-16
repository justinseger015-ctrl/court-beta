import requests
from bs4 import BeautifulSoup

url = "https://www.lacourt.org/criminalcalendar/ui/"
headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36"
}

response = requests.get(url, headers=headers)

if response.status_code == 200:
    soup = BeautifulSoup(response.text, "html.parser")
    print(soup.prettify())  # Check if case data is in HTML
else:
    print(f"Failed to fetch the page, status code: {response.status_code}")
