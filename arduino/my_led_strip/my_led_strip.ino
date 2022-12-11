#include <Adafruit_NeoPixel.h>
#include <WiFi.h>
#include <HTTPClient.h>

#define PIN 23
#define PIN_VCC 18
#define PIN_GND 21
#define NUMBER_OF_LEDS 40
#define MAX_BRIGHTNESS 255
#define MEU_ROSA createCor(252,2,149)
#define BRANCO createCor(0,0,0,255)
#define BRANCO_RGB createCor(255,255,255)
#define PRETO createCor(0,0,0,0)
#define AZUL_CEU createCor(2,0,244)
#define AMARELO_ESTRELAS createCor(255,251,0)

Adafruit_NeoPixel strip = Adafruit_NeoPixel(NUMBER_OF_LEDS, PIN, NEO_GRBW + NEO_KHZ800);

typedef struct {
  uint8_t r;
  uint8_t g;
  uint8_t b;
  uint8_t w;
}COR;

COR createCor(uint8_t r,uint8_t g,uint8_t b){
  COR c;
  c.r=r;
  c.g=g;
  c.b=b;
  c.w=0;
  return c;
}
COR createCor(uint8_t r,uint8_t g,uint8_t b,uint8_t w){
  COR c;
  c.r=r;
  c.g=g;
  c.b=b;
  c.w=w;
  return c;
}
COR corWithBrightness(COR cor,uint16_t bright){
  cor.r=cor.r*bright/255;
  cor.g=cor.g*bright/255;
  cor.b=cor.b*bright/255;
  cor.w=cor.w*bright/255;
  return cor;
}
uint32_t corToUInt(COR c){
  return strip.Color(c.r,c.g,c.b,c.w);
}

//PARA MUDAR FAZER
// GET /mode/<nome do modo>?r=123,g=123,b=123,w=123
typedef enum{
  EfadeEstatico=0,
  EcorEstatica,
  EpreencherUmAUm,
  EpreencherUmAUmBounce,
  EarcoIris,
  EarcoIrisCycle,
  EturnOff,
  EcintilarEstrelas
}modo;

uint8_t wait = 50;
modo modoLED = EcorEstatica;
COR cor = BRANCO;

IPAddress ip;
bool isWifiConnected = false;
WiFiServer server(80);
String header;
String linkRegistarServidor = "http://192.168.3.0:8080";

//TaskHandle_t TaskWifi;
TaskHandle_t TaskLED;

inline void setupWifi(){
  WiFi.disconnect(true);
  WiFi.mode(WIFI_STA);
  WiFi.begin("TVRS_AP","*Tavares123?*");
  WiFiEventId_t eventID = WiFi.onEvent([](WiFiEvent_t event, WiFiEventInfo_t info){
        isWifiConnected = true;
        ip = IPAddress(info.got_ip.ip_info.ip.addr);
        
    }, WiFiEvent_t::ARDUINO_EVENT_WIFI_STA_GOT_IP);
  Serial.print("Connecting");
  while(!isWifiConnected){
    Serial.print(".");
  }
  Serial.println();
  Serial.println(ip);
}
inline void registarIPNoServidor(){
  Serial.println("vou registar");
  String path = linkRegistarServidor + "/registar?ip=" + ip.toString();
  HTTPClient clientHTTP;
  clientHTTP.begin(path.c_str());
  clientHTTP.addHeader("Content-Type", "text/plain");
  int responseCode = clientHTTP.PUT(ip.toString());
  if(responseCode>0){
    String response = clientHTTP.getString();
  }
  clientHTTP.end();
}
void setup() {
  Serial.begin(115200);
  strip.begin();
  strip.setBrightness(255);
  // Initialize all pixels to 'off'
  for(int i =0;i<NUMBER_OF_LEDS;i++){
    strip.setPixelColor(i,corToUInt(BRANCO));
  }
  strip.show();
  setupWifi();
  server.begin();
  /*xTaskCreatePinnedToCore(
    loopWIFI, //funcao a executar na task
    "http server", //nome da task
    10000, //tamanho do stack para a task
    NULL, //argumentos da task
    1, //prioridade da task
    &TaskWifi,
    0 //meter a task no core 0
  );*/
  delay(500);
  registarIPNoServidor();
  createLEDThread();
}
inline void createLEDThread(){
  xTaskCreatePinnedToCore(
    loopLED, //funcao a executar na task
    "led controller", //nome da task
    8000, //tamanho do stack para a task
    NULL, //argumentos da task
    1, //prioridade da task
    &TaskLED,
    1 //meter a task no core 1
  );
}
long int currentTime = millis();
void loop(){
  WiFiClient client = server.available();
  if(client){
    parseRequest(client);
  }
  if(millis() - currentTime > 30000){
    registarIPNoServidor();
    currentTime = millis();
  }
}

void loopLED(void * pvParameters){
  for(;;){
    selectMode();
  }
}

inline void parseRequest(WiFiClient client){
  String currentLine = "";
  bool currentLineIsBlank = true;
  String response = "";
  while (client.connected()){
    if (client.available()){
      char c = client.read();
      if (c == '\n' && currentLineIsBlank){
        currentLine.replace("%3F","?");
        String requestPath = currentLine.substring(3,currentLine.indexOf("HTTP/1.1"));
        if(requestPath.indexOf("/mode/")>=0 && requestPath.indexOf("?") >=0){
          String mode = requestPath.substring(requestPath.indexOf("/mode/")+6,requestPath.indexOf("?"));
          String rgbw = requestPath.substring(requestPath.indexOf("?")+1);
          int r = requestPath.substring(requestPath.indexOf("r=")+2,requestPath.indexOf("g=")).toInt();
          int g = requestPath.substring(requestPath.indexOf("g=")+2,requestPath.indexOf("b=")).toInt();
          int b = requestPath.substring(requestPath.indexOf("b=")+2,requestPath.indexOf("w=")).toInt();
          int w = requestPath.substring(requestPath.indexOf("w=")+2,requestPath.indexOf("br=")).toInt();
          int br = requestPath.substring(requestPath.indexOf("br=")+3).toInt();
          currentLine = "Mode: " + mode + "\nCores: (" + r + "," + g + "," + b + "," + w + ") with brightness= " + br;
          cor = w == 0 ? createCor(r,g,b) : createCor(r,g,b,w);
          if(br > 0){
            cor = corWithBrightness(cor,br);
          }
          bool res = compararModos(mode);
          if(res)
            response = "HTTP/1.1 200 OK";
          else {
            response = "HTTP/1.1 404 Not Found";
            currentLine+="\nNAO E VALIDO";
          }
        }else if(requestPath.indexOf("/wait/")>=0){
          String aux = requestPath.substring(requestPath.indexOf("/wait/")+6);
          aux = aux.substring(0,aux.indexOf(" "));
          int waitNovo = aux.toInt();
          if(waitNovo <= 0){
            waitNovo = 1;
          }
          wait = waitNovo;          
          response = "HTTP/1.1 200 OK";
          currentLine = "Wait atualizado";
        }else{
          response = "HTTP/1.1 404 Not Found";
          currentLine ="\ncaminho nao existe";
        }
	      response += "\nContent-Type: text/html";
	      response += "\nConnection: close";  // the connection will be closed after completion of the response
	      response += "\n\n<!DOCTYPE HTML>";
	      response += "<html>";
        response += "<body><h1>"+currentLine+"</h1></body>";
	      response += "</html>";
	      break;
      }
      currentLine += c;
      if (c == '\n') {
        // you're starting a new line
        currentLineIsBlank = true;
	    } else if (c != '\r') {
	      // you've gotten a character on the current line
	      currentLineIsBlank = false;
	    }
    }
  }
  
  client.println(response);
  delay(10);// give the web browser time to receive the data
  client.stop();
  vTaskDelete(TaskLED);
  createLEDThread();
  Serial.println("client disconnected");
}
inline void selectMode(){
  switch(modoLED){
    case EfadeEstatico:
      fadeEstatico();
      break;
    case EcorEstatica:
      corEstatica();
      break;
    case EpreencherUmAUm:
      preencherUmAUm();
      break;
    case EpreencherUmAUmBounce:
      preencherUmAUmBounce();
      break;
    case EarcoIris:
      arcoIris();
      break;
    case EarcoIrisCycle:
      arcoIrisCycle();
      break;
    case EturnOff:
      desligarLeds();
      break;
    case EcintilarEstrelas:
      cintilarEstrelas();
      break;
  }
}
inline bool compararModos(String modo){
  modo.toLowerCase();
  bool isCorrect = true;
  if(modo == "fadeestatico"){
    modoLED = EfadeEstatico;
  }else if(modo == "corestatica"){
    modoLED = EcorEstatica;
  }
  else if(modo == "preencherumaum"){
    modoLED = EpreencherUmAUm;
  }
  else if(modo == "preencherumaumbounce"){
    modoLED = EpreencherUmAUmBounce;
  }
  else if(modo == "arcoiris"){
    modoLED = EarcoIris;
  }
  else if(modo == "arcoiriscycle"){
    modoLED = EarcoIrisCycle;
  }else if(modo == "turnoff"){
    modoLED = EturnOff;
  }else if(modo == "cintilarestrelas"){
    modoLED = EcintilarEstrelas;
  }
  else{
    isCorrect = false;
  }
  return isCorrect;
}

void cintilarEstrelas(){
  strip.show();
  for (int i = 0; i<NUMBER_OF_LEDS; i++) {
    strip.setPixelColor(i, corToUInt(AZUL_CEU));
  }
  int array[10];
  for(int i = 0; i<10; i++){
    array[i] = random(NUMBER_OF_LEDS);
    strip.setPixelColor(array[i],corToUInt(AMARELO_ESTRELAS));
    strip.show();
    delay(wait*3);    
  }
  for(int i = 0; i<10; i++){
    strip.setPixelColor(array[i],corToUInt(AZUL_CEU));
    strip.show();
    delay(wait*3);    
  }
  delay(wait*15);
}
inline void desligarLeds(){
  strip.show();
}
void fadeEstatico(){
  for(int i = 0; i<=255; i++){
    for(int j = 0; j<NUMBER_OF_LEDS; j++){
      strip.setPixelColor(j,corToUInt(corWithBrightness(cor,i)));
    }
    strip.show();
    delay(wait);
  }
  delay(wait*2);
  for(int i = 255; i>=0; i--){
    for(int j = 0; j<NUMBER_OF_LEDS; j++){
      strip.setPixelColor(j,corToUInt(corWithBrightness(cor,i)));
    }
    strip.show();
    delay(wait);
  }
  delay(wait*2);
}
inline void corEstatica(){
  for(int i = 0; i<NUMBER_OF_LEDS; i++){
    strip.setPixelColor(i,corToUInt(cor));
  }
  strip.show();
}
void preencherUmAUm(){
  for(uint16_t i=0; i<NUMBER_OF_LEDS; i++) {
    strip.setPixelColor(i, corToUInt(cor));
    strip.show();
    delay(wait);
  }
  delay(wait/20);
  for(uint16_t i=0; i<NUMBER_OF_LEDS; i++) {
    strip.setPixelColor(i, corToUInt(PRETO));
    strip.show();
    delay(wait/2);
  }
  delay(wait/20);
}
void preencherUmAUmBounce(){
  int EyeSize = 5;
  for(int i = 0; i < NUMBER_OF_LEDS-EyeSize-2; i++) {
    strip.show();
    strip.setPixelColor(i, corToUInt(corWithBrightness(cor,25)));
    for(int j = 1; j <= EyeSize; j++) {
      strip.setPixelColor(i+j, corToUInt(cor)); 
    }
    strip.setPixelColor(i+EyeSize+1, corToUInt(corWithBrightness(cor,25)));
    strip.show();
    delay(wait);
  }

  delay(wait);

  for(int i = NUMBER_OF_LEDS-EyeSize-2; i > 0; i--) {
    strip.show();
    strip.setPixelColor(i, corToUInt(corWithBrightness(cor,25)));
    for(int j = 1; j <= EyeSize; j++) {
      strip.setPixelColor(i+j, corToUInt(cor)); 
    }
    strip.setPixelColor(i+EyeSize+1, corToUInt(corWithBrightness(cor,25)));
    strip.show();
    delay(wait);
  }
  
  delay(wait);
  /*for(uint16_t i=0; i<NUMBER_OF_LEDS; i++) {
    strip.setPixelColor(i, corToUInt(cor));
    strip.show();
    delay(wait);
  }
  for(uint16_t i=0; i<NUMBER_OF_LEDS; i++) {
    strip.setPixelColor(i, corToUInt(PRETO));
    strip.show();
    delay(wait/5);
  }
  //delay(wait/20);
  for(uint16_t i=0; i<NUMBER_OF_LEDS; i++) {
    strip.setPixelColor(NUMBER_OF_LEDS-i, corToUInt(cor));
    strip.show();
    delay(wait);
  }
  for(uint16_t i=0; i<NUMBER_OF_LEDS; i++) {
    strip.setPixelColor(NUMBER_OF_LEDS-i, corToUInt(PRETO));
    strip.show();
    delay(wait/5);
  }
  delay(wait/20);*/
}
void arcoIris(){
  for(uint16_t j=0; j<256; j++) {
    for(uint16_t i=0; i<NUMBER_OF_LEDS; i++) {
      strip.setPixelColor(i, Wheel((i+j) & 255));
    }
    strip.show();
    delay(wait);
  }  
}
void arcoIrisCycle() {
  for(uint16_t j=0; j<256*5; j++) { // 5 cycles of all colors on wheel
    for(uint16_t i=0; i< NUMBER_OF_LEDS; i++) {
      strip.setPixelColor(i, Wheel(((i * 256 / NUMBER_OF_LEDS) + j) & 255));
    }
    strip.show();
    delay(wait);
  }
}


// Input a value 0 to 255 to get a color value.
// The colours are a transition r - g - b - back to r.
uint32_t Wheel(byte WheelPos) {
  WheelPos = 255 - WheelPos;
  if(WheelPos < 85) {
    return strip.Color(255 - WheelPos * 3, 0, WheelPos * 3);
  }
  if(WheelPos < 170) {
    WheelPos -= 85;
    return strip.Color(0, WheelPos * 3, 255 - WheelPos * 3);
  }
  WheelPos -= 170;
  return strip.Color(WheelPos * 3, 255 - WheelPos * 3, 0);
}
