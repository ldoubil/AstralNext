use mdns::{Record, RecordType};
use std::collections::HashMap;
use std::sync::RwLock;
use tokio::sync::mpsc;
use uuid::Uuid;

lazy_static::lazy_static! {
    static ref DISCOVERED_SERVICES: RwLock<HashMap<String, ServiceInfo>> = RwLock::new(HashMap::new());
}

pub struct ServiceInfo {
    pub name: String,
    pub host: String,
    pub port: u16,
    pub txt: HashMap<String, String>,
}

pub async fn register_service(port: u16) -> Result<String, String> {
    let service_name = format!("astral-{}", Uuid::new_v4().to_string().split('-').next().unwrap());
    
    let mdns = mdns::Responder::new().map_err(|e| format!("Failed to create responder: {}", e))?;
    
    let _handle = mdns.register(
        format!("{}._astral._tcp.local", service_name),
        "_astral._tcp.local",
        "localhost",
        port,
        &["peer_id=1", "version=1.0.0"],
    ).map_err(|e| format!("Failed to register service: {}", e))?;
    
    Ok(service_name)
}

pub async fn discover_services(duration_ms: u64) -> Result<Vec<ServiceInfo>, String> {
    let stream = mdns::discover::all("_astral._tcp.local")
        .map_err(|e| format!("Failed to discover services: {}", e))?;
    
    let (tx, mut rx) = mpsc::channel(32);
    
    tokio::spawn(async move {
        let mut discovered = HashMap::new();
        
        while let Ok(Ok(response)) = stream.recv().await {
            let mut service_info = ServiceInfo {
                name: "".to_string(),
                host: "".to_string(),
                port: 0,
                txt: HashMap::new(),
            };
            
            for record in response.answers() {
                match record.record_type() {
                    RecordType::SRV => {
                        if let Record::SRV(srv) = record {
                            service_info.name = srv.name().to_string();
                            service_info.port = srv.port();
                        }
                    }
                    RecordType::A | RecordType::AAAA => {
                        if let Record::A(a) = record {
                            service_info.host = a.addr().to_string();
                        }
                    }
                    RecordType::TXT => {
                        if let Record::TXT(txt) = record {
                            for entry in txt.txt_data() {
                                if let Some((key, value)) = entry.split_once('=') {
                                    service_info.txt.insert(key.to_string(), value.to_string());
                                }
                            }
                        }
                    }
                    _ => {}
                }
            }
            
            if !service_info.name.is_empty() && service_info.port > 0 {
                discovered.insert(service_info.name.clone(), service_info);
            }
        }
        
        let _ = tx.send(discovered).await;
    });
    
    tokio::time::sleep(tokio::time::Duration::from_millis(duration_ms)).await;
    
    if let Ok(services) = rx.recv().await {
        Ok(services.into_values().collect())
    } else {
        Ok(Vec::new())
    }
}

pub fn get_discovered_services() -> Vec<ServiceInfo> {
    DISCOVERED_SERVICES.read().unwrap().values().cloned().collect()
}