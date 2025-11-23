from locust import HttpUser, task, between

class WebsiteUser(HttpUser):
    # Wait time between tasks (simulates real user)
    wait_time = between(1, 3)

    @task(1)
    def index(self):
        self.client.get("/")

    @task(3)
    def db_test(self):
        # This endpoint generates load on the DB
        self.client.get("/db-test")

    @task(1)
    def health(self):
        self.client.get("/health")
