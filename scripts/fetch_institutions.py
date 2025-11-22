import os
import requests

# Configuration
OUTPUT_DIR = "../assets/logos"
BANKS = [
    {"name": "Boursorama", "url": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/26/Boursorama_Banque_Logo.svg/2560px-Boursorama_Banque_Logo.svg.png"},
    {"name": "Trade Republic", "url": "https://upload.wikimedia.org/wikipedia/commons/thumb/a/aa/Trade_Republic_Logo.svg/1200px-Trade_Republic_Logo.svg.png"},
    {"name": "Revolut", "url": "https://upload.wikimedia.org/wikipedia/commons/thumb/6/66/Revolut_logo_2021.svg/1200px-Revolut_logo_2021.svg.png"},
    {"name": "Degiro", "url": "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d5/Degiro_logo.svg/1200px-Degiro_logo.svg.png"},
    {"name": "Interactive Brokers", "url": "https://upload.wikimedia.org/wikipedia/commons/thumb/8/83/Interactive_Brokers_logo.svg/1200px-Interactive_Brokers_logo.svg.png"},
    {"name": "Binance", "url": "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Binance_Logo.svg/1200px-Binance_Logo.svg.png"},
    {"name": "Coinbase", "url": "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Coinbase.svg/1200px-Coinbase.svg.png"},
    {"name": "Kraken", "url": "https://upload.wikimedia.org/wikipedia/commons/thumb/8/8b/Kraken_logo.png/1200px-Kraken_logo.png"},
    {"name": "Fortuneo", "url": "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a6/Logo_Fortuneo_2018.svg/1200px-Logo_Fortuneo_2018.svg.png"},
    {"name": "Credit Agricole", "url": "https://upload.wikimedia.org/wikipedia/fr/thumb/6/6f/Logo_Cr%C3%A9dit_Agricole.svg/1200px-Logo_Cr%C3%A9dit_Agricole.svg.png"},
    {"name": "BNP Paribas", "url": "https://upload.wikimedia.org/wikipedia/commons/thumb/1/12/BNP_Paribas.svg/1200px-BNP_Paribas.svg.png"},
    {"name": "Societe Generale", "url": "https://upload.wikimedia.org/wikipedia/fr/thumb/5/5e/Soci%C3%A9t%C3%A9_G%C3%A9n%C3%A9rale.svg/1200px-Soci%C3%A9t%C3%A9_G%C3%A9n%C3%A9rale.svg.png"},
]

def download_logo(name, url):
    try:
        response = requests.get(url)
        response.raise_for_status()
        
        # Determine extension
        ext = "png"
        if "svg" in url and "png" not in url:
             # Simple check, ideally use content-type
             pass
        
        filename = f"{name.lower().replace(' ', '_')}.{ext}"
        filepath = os.path.join(OUTPUT_DIR, filename)
        
        with open(filepath, 'wb') as f:
            f.write(response.content)
        print(f"Downloaded: {name} -> {filepath}")
        
    except Exception as e:
        print(f"Error downloading {name}: {e}")

def main():
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)
        print(f"Created directory: {OUTPUT_DIR}")
        
    print(f"Starting download of {len(BANKS)} bank logos...")
    for bank in BANKS:
        download_logo(bank["name"], bank["url"])
    print("Done.")

if __name__ == "__main__":
    main()
