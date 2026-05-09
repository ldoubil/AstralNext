fn main() {
    // 链接 easytier 在 Windows 上需要的 Npcap SDK。
    // 优先读取 NPCAP_SDK_DIR 环境变量，缺省回退到 F:\npcap\x64。
    if std::env::var("CARGO_CFG_TARGET_OS").as_deref() == Ok("windows") {
        let sdk = std::env::var("NPCAP_SDK_DIR").unwrap_or_else(|_| "F:/npcap/x64".to_string());
        println!("cargo:rerun-if-env-changed=NPCAP_SDK_DIR");
        println!("cargo:rustc-link-search=native={}", sdk);
    }
}
