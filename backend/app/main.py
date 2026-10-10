from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.api.router import api_router
from app.agents.poller import event_poller


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Automatically start automated climate-news monitoring job
    await event_poller.start_monitoring(interval_seconds=60)
    # Perform immediate first poll
    await event_poller.poll_once()
    yield
    # Gracefully stop background job
    await event_poller.stop_monitoring()


app = FastAPI(
    title="CLIMATWIN Intelligence Engine API",
    description="Agentic climate-risk intelligence platform API for investment portfolios.",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# Configure CORS for mobile / web frontend connectivity
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix="/api")


@app.get("/")
def root():
    return {
        "message": "CLIMATWIN API is running",
        "documentation": "/docs",
        "health": "/api/v1/health",
        "poller_status": event_poller.get_status(),
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host=settings.HOST, port=settings.PORT, reload=settings.DEBUG)
