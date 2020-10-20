<?php
namespace rendermani\wsdl\client;

class Generator  {
    private $classMap = [];
    private $namespace;
    private $lang = "php"; 
    private $wsdl;
    private $apiId;
    private $apiName;
    private $outputPath;
    private $configPath;
    public function __construct($apiName,$apiId,$wsdl)
    {
        $this->apiName = $apiName;
        $this->apiId = $apiId;
        $this->wsdl = $wsdl; 
    }
    public function setClassMap (array $classMap) {
        $this->classMap = $classMap;
    }
    public function setNamespace (string $namespace) {
        $this->namespace = $namespace;
    }  
    public function setCodeLang(string $lang) {
        $this->lang = $lang;
    }
    public function generate() {        
       $structure = $this->generateStructure();
       $this->generateCode($structure,"service",true);    
       $this->generateCode($structure,"lib",false);    
       $this->generateCode($structure,"db",false,"Db");    
       $this->generateCode($structure,"api",false,"Api");    

    }
    public function setConfigPath($configPath) {
        $this->configPath = $configPath; 
    }
    public function setOutputPath($outputPath) {
        $this->outputPath = $outputPath; 
    }
    private function generateCode($xmlString,$dir,$replace,$fileSuffix="") {
        echo "\ngenerate $dir\n";
        if(!file_exists($this->outputPath)) {
            mkdir($this->outputPath,077,true);   
        }
        $fullPath = $this->outputPath."/".$dir."/".$this->apiId."/";
        if(!file_exists($fullPath)) {
            mkdir($fullPath,077,true);   
        }
        $filePath = realpath(__DIR__."/../xslt/".$this->lang."-".$dir.".xsl");
        if(!file_exists($filePath)) {
            throw new \Exception("Could not load XSLT: ". $filePath."\n");
        }
        $xsl = new \DOMDocument("1.0","UTF-8");
        $xsl->load($filePath);
        $proc = new \XSLTProcessor;
        $proc->importStyleSheet($xsl);
        $this->setXsltParams($proc);

        $xml = new  \DOMDocument("1.0","UTF-8");
        $xml->loadXML($xmlString);   
        foreach($xml->firstChild->childNodes as $key => $child) {
            /**
             * @var \DOMElement $child
             */
            if(get_class($child)=="DOMElement") {
                $childDoc  = new  \DOMDocument("1.0","UTF-8");
                $childDoc->appendChild($childDoc->importNode($child,true));  
                $proc = new \XSLTProcessor;
                $proc->importStyleSheet($xsl);
                $this->setXsltParams($proc);     
                $fileName = $fullPath.$child->getAttribute("name").$fileSuffix.".php";
                if(file_exists($fileName) && $replace == false){
                    echo "Existing ".$fileName ." was not overwritten\n"; 
                    continue;
                } else {
                    echo "Write ". $fileName."\n";
                }
                $proc->transformToUri($childDoc,$fileName);
            }            
        }
        return;       
    }
    private function generateStructure() {
        $filePath = realpath(__DIR__."/../xslt/structure.xsl");
        $xml = new  \DOMDocument("1.0","UTF-8");
        $xml->load($this->wsdl);
        
        $xsl = new \DOMDocument("1.0","UTF-8");
        $xsl->load($filePath);
        $proc = new \XSLTProcessor;
        $proc->importStyleSheet($xsl);
        $this->setXsltParams($proc);

       return  $proc->transformToXml($xml);
    }
    private function setXsltParams(\XSLTProcessor $proc) {
        $proc->setParameter('','config-file',$this->configPath."/".$this->apiId.".xml");
        $proc->setParameter('','api-name',$this->apiName);        
    }
}