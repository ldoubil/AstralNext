use hyper::{Body, Request, Response, Server, StatusCode};
use hyper::service::{make_service_fn, service_fn};
use rand::Rng;
use std::net::SocketAddr;
use std::sync::RwLock;

lazy_static::lazy_static! {
    static ref CURRENT_PORT: RwLock<Option<u16>> = RwLock::new(None);
}

pub struct HttpServerHandle {
    port: u16,
}

impl HttpServerHandle {
    pub fn port(&self) -> u16 {
        self.port
    }
    
    pub async fn stop(self) {
        *CURRENT_PORT.write().unwrap() = None;
    }
}

pub async fn start_server() -> Result<HttpServerHandle, String> {
    let port = find_available_port().ok_or_else(|| "Failed to find available port".to_string())?;
    
    let addr = SocketAddr::from(([0, 0, 0, 0], port));
    
    let make_svc = make_service_fn(|_conn| async {
        Ok::<_, hyper::Error>(service_fn(handle_request))
    });
    
    let server = Server::bind(&addr).serve(make_svc);
    
    *CURRENT_PORT.write().unwrap() = Some(port);
    
    tokio::spawn(async move {
        if let Err(e) = server.await {
            eprintln!("HTTP server error: {}", e);
        }
    });
    
    Ok(HttpServerHandle { port })
}

fn find_available_port() -> Option<u16> {
    let mut rng = rand::thread_rng();
    
    for _ in 0..100 {
        let port = rng.gen_range(10000..65535);
        
        if let Ok(listener) = std::net::TcpListener::bind(("127.0.0.1", port)) {
            drop(listener);
            return Some(port);
        }
    }
    
    None
}

async fn handle_request(req: Request<Body>) -> Result<Response<Body>, hyper::Error> {
    let path = req.uri().path();
    
    match path {
        "/api/avatar" => handle_avatar(req).await,
        "/api/info" => handle_info(req).await,
        _ => Ok(Response::builder()
            .status(StatusCode::NOT_FOUND)
            .body(Body::from("Not Found"))
            .unwrap()),
    }
}

async fn handle_avatar(_req: Request<Body>) -> Result<Response<Body>, hyper::Error> {
    let avatar_data = generate_default_avatar();
    
    Ok(Response::builder()
        .status(StatusCode::OK)
        .header("Content-Type", "image/png")
        .body(Body::from(avatar_data))
        .unwrap())
}

async fn handle_info(_req: Request<Body>) -> Result<Response<Body>, hyper::Error> {
    let info = serde_json::json!({
        "peer_id": 1,
        "hostname": "localhost",
        "version": "1.0.0",
        "platform": "windows",
    });
    
    Ok(Response::builder()
        .status(StatusCode::OK)
        .header("Content-Type", "application/json")
        .body(Body::from(info.to_string()))
        .unwrap())
}

fn generate_default_avatar() -> Vec<u8> {
    vec![
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
        0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x20,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x73, 0x7A, 0x7A,
        0xF4, 0x00, 0x00, 0x00, 0x01, 0x73, 0x52, 0x47,
        0x42, 0x00, 0xAE, 0xCE, 0x1C, 0xE9, 0x00, 0x00,
        0x00, 0x36, 0x49, 0x44, 0x41, 0x54, 0x38, 0x8D,
        0x63, 0x60, 0x18, 0x05, 0xA3, 0x60, 0x14, 0x8C,
        0x02, 0x08, 0x00, 0x00, 0xFF, 0xFF, 0x03, 0x00,
        0x01, 0x00, 0x01, 0x5D, 0xF6, 0xF6, 0xF6, 0xF6,
        0x10, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E,
        0x44, 0xAE, 0x42, 0x60, 0x82,
    ]
}

pub fn get_current_port() -> Option<u16> {
    *CURRENT_PORT.read().unwrap()
}