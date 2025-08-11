# Smart Personal Financer — title

Description

Smart Personal Financer is a platform that helps users track and manage expenses, define and monitor savings goals, and receive AI-powered recommendations to make smarter financial decisions. The implementation separates responsibilities across three technology stacks: Scala for AI/ML model training and artifact creation, FastAPI for model inference and AI microservice, and ASP.NET Core for the core back-end API that manages users, expenses, and goals and proxies recommendations from the AI service.

## Tech Stack

- Scala (AI/ML model training and artifact generation)
- FastAPI (Python) (AI inference microservice / recommendation API)
- ASP.NET Core (C#) (primary back-end API for expenses and goals)

## Requirements

- Expense management (create/read/update/delete expenses)
- Savings goal creation and tracking
- AI-powered financial recommendations (spending adjustments, saving tips)

## Installation

This repository is organized as three services. Each service has its own setup steps and environment variables.

1) Scala (AI/ML model project)

Required files normally included:
- build.sbt
- project/plugins.sbt
- src/main/scala/ModelTrainer.scala
- src/main/scala/Model.scala

Setup commands:

- Install JDK 11+ and sbt.
- From the scala/ directory:
  - Restore/build: sbt compile
  - Run training that writes a model artifact: sbt "runMain com.example.ModelTrainer --output ./models/recommender-model.bin --data ./data/training.csv"
  - (Optional) Create a runnable JAR (if configured with sbt-assembly): sbt assembly

Environment variables (examples):
- SCALA_TRAINING_DATA_PATH (path to CSV training data; default: ./data/training.csv)
- SCALA_MODEL_OUTPUT_PATH (where to save trained model; default: ./models/recommender-model.bin)

Notes: the Scala project produces a model artifact used by the FastAPI inference service.

2) FastAPI (AI inference microservice)

Required files normally included:
- requirements.txt
- app/main.py (FastAPI app)
- app/recommender.py (loads model artifact and exposes /recommendations)
- app/schemas.py (pydantic schemas for requests/responses)

Setup commands:

- Install Python 3.9+.
- From the fastapi/ directory:
  - Create virtualenv: python -m venv .venv
  - Activate: source .venv/bin/activate  (macOS/Linux) or .venv\Scripts\activate (Windows)
  - Install deps: pip install -r requirements.txt
  - Run dev server: uvicorn app.main:app --host 0.0.0.0 --port 8001 --reload

Environment variables (examples):
- MODEL_PATH (path to the trained model artifact produced by Scala; default: ./models/recommender-model.bin)
- FASTAPI_HOST (default: 0.0.0.0)
- FASTAPI_PORT (default: 8001)

Notes: FastAPI loads the Scala-produced model artifact for inference and exposes a simple JSON API for recommendations.

3) ASP.NET Core (primary back-end API)

Required files normally included:
- SmartPersonalFinancer.csproj
- Program.cs (or Program.cs + Startup.cs for older templates)
- Controllers/ExpensesController.cs
- Controllers/GoalsController.cs
- Services/RecommenderProxy.cs
- appsettings.json

Setup commands:

- Install .NET SDK 6.0+.
- From the aspnetcore/ directory:
  - Restore packages: dotnet restore
  - Build: dotnet build
  - Run: dotnet run --urls "http://localhost:5000"

Environment variables (examples):
- ASPNETCORE_ENVIRONMENT (Development/Production)
- STORAGE_PATH (file path used for local JSON persistence for expenses and goals; default: ./data/storage.json)
- RECOMMENDER_URL (URL of the FastAPI service, e.g., http://localhost:8001/recommendations)

Notes: This service implements CRUD for expenses and savings goals and calls the FastAPI recommender for AI suggestions. For a production-ready deployment, replace file-based storage with a proper database and secure the services.

## Usage

High-level run order and example local usage:

1. Train the model (Scala) and produce a model artifact.
   - cd scala
   - sbt "runMain com.example.ModelTrainer --output ./models/recommender-model.bin --data ./data/training.csv"

2. Start the FastAPI inference service (loads model artifact):
   - cd fastapi
   - source .venv/bin/activate
   - export MODEL_PATH=../scala/models/recommender-model.bin
   - uvicorn app.main:app --host 0.0.0.0 --port 8001 --reload

3. Start the ASP.NET Core back-end:
   - cd aspnetcore
   - set RECOMMENDER_URL=http://localhost:8001/recommendations  (Windows: setx or use PowerShell)
   - dotnet run --urls "http://localhost:5000"

4. Example flows:
   - Create an expense (POST http://localhost:5000/api/expenses)
   - Create a savings goal (POST http://localhost:5000/api/goals)
   - Request recommendations for a user (GET http://localhost:5000/api/recommendations?userId={id}) — the back-end proxies this to the FastAPI service which runs inference using the Scala model artifact.

## Implementation Steps

1. Initialize three subprojects:
   - scala/ (sbt project for model training and artifact generation)
   - fastapi/ (Python/uvicorn FastAPI microservice for inference)
   - aspnetcore/ (ASP.NET Core Web API project for expense and goals management)

2. Scala: implement ModelTrainer and a simple model API
   - Add build.sbt and project/plugins.sbt
   - Implement src/main/scala/ModelTrainer.scala that reads CSV training data and serializes a lightweight model to disk (e.g., a feature-weight file or serialized object)
   - Define a simple Model.scala with serialization/deserialization utilities and an API for scoring inputs

3. FastAPI: implement inference API
   - Create requirements.txt (fastapi, uvicorn, pydantic, joblib or pickle if used)
   - Implement app/main.py to start the FastAPI app and load the model artifact using the MODEL_PATH env var
   - Implement app/recommender.py with inference logic that converts incoming JSON features into model inputs and returns recommendations
   - Add healthcheck endpoint (GET /health)

4. ASP.NET Core: implement primary business API
   - Create an ASP.NET Core Web API project (dotnet new webapi)
   - Implement Controllers/ExpensesController.cs with CRUD endpoints that persist to a JSON file at STORAGE_PATH
   - Implement Controllers/GoalsController.cs for savings goal operations
   - Implement Services/RecommenderProxy.cs that calls RECOMMENDER_URL and transforms responses into the app domain
   - Configure appsettings.json and Program.cs to wire services and environment variables

5. Integration and local run scripts
   - Document commands in README to run the three services locally in the specified order
   - Implement simple sample data files (scala/data/training.csv, fastapi/test_requests.json, aspnetcore/data/storage.json)

6. Testing and sample requests
   - Provide curl/postman examples for creating expenses, goals, and requesting recommendations
   - Add unit tests in each project (sbt test, pytest for FastAPI, xUnit for ASP.NET Core)

7. Optional productionization steps
   - Replace file-based storage with a database connection configured via environment variables
   - Add authentication/authorization to the ASP.NET Core API
   - Containerize services and orchestrate with your preferred tooling (not included in this repo by default)

(Optional) ## API Endpoints

The repository exposes two API layers: the ASP.NET Core primary API and the FastAPI inference API. Example endpoints below assume default local ports (ASP.NET Core: 5000, FastAPI: 8001).

ASP.NET Core (Primary Back-End)
- POST /api/expenses
  - Create a new expense
  - Body: { "userId": "string", "amount": number, "category": "string", "date": "YYYY-MM-DD", "note": "string" }
  - Response: created expense with id

- GET /api/expenses?userId={userId}
  - List expenses for a user

- PUT /api/expenses/{id}
  - Update an expense

- DELETE /api/expenses/{id}
  - Delete an expense

- POST /api/goals
  - Create a savings goal
  - Body: { "userId": "string", "targetAmount": number, "deadline": "YYYY-MM-DD", "title": "string" }

- GET /api/goals?userId={userId}
  - List savings goals for a user

- GET /api/recommendations?userId={userId}
  - Obtain AI-powered recommendations for a user
  - The controller gathers user expense summaries and calls the FastAPI recommender at RECOMMENDER_URL, returning the AI suggestions

FastAPI (AI Inference Service)
- GET /health
  - Returns simple status: { "status": "ok" }

- POST /recommendations
  - Accepts preprocessed user features and returns recommendations
  - Body: { "userId": "string", "features": { ... } }
  - Response: { "userId": "string", "recommendations": [ { "type": "reduce_category", "category": "dining", "suggested_amount": 120.0, "confidence": 0.82 }, ... ] }

Notes on integration:
- RECOMMENDER_URL in the ASP.NET Core app should point to the FastAPI /recommendations endpoint.
- MODEL_PATH in FastAPI must point to the model artifact produced by the Scala project.

If you need example request payloads or starter project templates for any of the three stacks, open an issue or request the specific scaffolding for scala/ fastapi/ or aspnetcore/ subfolders and I will provide them.