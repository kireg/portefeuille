import os
import requests

# Configuration
# Utilise le chemin du script pour déterminer le chemin absolu vers assets/logos
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_DIR = os.path.join(SCRIPT_DIR, "..", "assets", "logos")

BANKS = [
    {"name": "Boursorama", "domain": "boursorama.com"},
    {"name": "Trade Republic", "domain": "traderepublic.com"},
    {"name": "Revolut", "domain": "revolut.com"},
    {"name": "Degiro", "domain": "degiro.com"},
    {"name": "Interactive Brokers", "domain": "interactivebrokers.com"},
    {"name": "Binance", "domain": "binance.com"},
    {"name": "Coinbase", "domain": "coinbase.com"},
    {"name": "Kraken", "domain": "kraken.com"},
    {"name": "Fortuneo", "domain": "fortuneo.fr"},
    {"name": "Credit Agricole", "domain": "credit-agricole.fr"},
    {"name": "BNP Paribas", "domain": "mabanque.bnpparibas"},
    {"name": "Societe Generale", "domain": "societegenerale.fr"},
]

def download_logo(name, domain):
    url = f"https://logo.clearbit.com/{domain}"
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0'
        }
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        
        filename = f"{name.lower().replace(' ', '_')}.png"
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
        download_logo(bank["name"], bank["domain"])
    print("Done.")

if __name__ == "__main__":
    main()
