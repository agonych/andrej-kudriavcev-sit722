import os
import sys
import time
import requests


def check_health(base_url, service_name):
    """Check /health endpoint of a service"""
    url = f"http://{base_url}/health"
    print(f"Checking {service_name} health at {url}")
    r = requests.get(url, timeout=10)
    r.raise_for_status()
    data = r.json()
    assert data["status"] == "ok"
    assert data["service"] == service_name
    print(f"✅ {service_name} health OK")


def wait_for_all_services(services, max_attempts=5, delay=10):
    """
    Retry health checks until all services report healthy.
    services: list of (base_url, service_name) tuples
    """
    for attempt in range(1, max_attempts + 1):
        try:
            for base_url, service_name in services:
                check_health(base_url, service_name)
            print("🎉 All services healthy!")
            return
        except Exception as e:
            print(f"⚠️ Attempt {attempt} failed: {e}")
            if attempt < max_attempts:
                print(f"Retrying in {delay} seconds...")
                time.sleep(delay)
            else:
                print("❌ Services did not become healthy in time")
                raise


def test_product_service(base_url):
    # Create product
    product = {
        "name": "Test",
        "description": "Test",
        "price": 1,
        "stock_quantity": 1,
        "image_url": ""
    }
    r = requests.post(f"http://{base_url}/products/", json=product, timeout=10)
    r.raise_for_status()
    created = r.json()
    assert created["name"] == "Test"
    pid = created["product_id"]

    # List products
    r = requests.get(f"http://{base_url}/products/", timeout=10)
    r.raise_for_status()
    products = r.json()
    assert any(p["product_id"] == pid for p in products)
    print("✅ Product service create/list OK")


def test_customer_service(base_url):
    customer = {
        "email": "user@example.com",
        "first_name": "string",
        "last_name": "string",
        "phone_number": "string",
        "shipping_address": "string",
        "password": "string12345"
    }
    r = requests.post(f"http://{base_url}/customers/", json=customer, timeout=10)
    r.raise_for_status()
    created = r.json()
    cid = created["customer_id"]

    r = requests.get(f"http://{base_url}/customers/", timeout=10)
    r.raise_for_status()
    customers = r.json()
    assert any(c["customer_id"] == cid for c in customers)
    print("✅ Customer service create/list OK")


def test_order_service(base_url):
    order = {
        "user_id": 1,
        "shipping_address": "string",
        "status": "pending",
        "items": [
            {"product_id": 1, "quantity": 1, "price_at_purchase": 1}
        ]
    }
    r = requests.post(f"http://{base_url}/orders/", json=order, timeout=10)
    r.raise_for_status()
    created = r.json()
    assert created["status"] == "pending"
    assert created["items"]
    print("✅ Order service create/list OK")


def test_frontend(base_url):
    url = f"http://{base_url}"
    print(f"Checking frontend at {url}")
    r = requests.get(url, timeout=10)
    r.raise_for_status()
    assert r.status_code == 200
    print("✅ Frontend reachable")


if __name__ == "__main__":
    try:
        product_ip = os.environ["PRODUCT_IP"]
        customer_ip = os.environ["CUSTOMER_IP"]
        order_ip = os.environ["ORDER_IP"]
        frontend_ip = os.environ["FRONTEND_IP"]

        # Step 1: Wait for all backends to be healthy
        wait_for_all_services([
            (f"{product_ip}:8000", "product-service"),
            (f"{customer_ip}:8002", "customer-service"),
            (f"{order_ip}:8001", "order-service")
        ])

        # Step 2: Run functional tests
        test_product_service(f"{product_ip}:8000")
        test_customer_service(f"{customer_ip}:8002")
        test_order_service(f"{order_ip}:8001")
        test_frontend(frontend_ip)

    except Exception as e:
        print(f"❌ Test failed: {e}")
        sys.exit(1)
