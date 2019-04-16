<?php

class XsltWsdlGenerator  {
    private $classMap = [];
    private $namespace;
    private $lang = "php"; 
    private $wsdl;
    private $configFile;
    private $apiName;
    private $outputPath;
    public function __construct($apiName,$configFile,$wsdl)
    {
        $this->apiName = $apiName;
        $this->configFile = $configFile;
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
       $this->generateCode($structure,"db",false);    
       $this->generateCode($structure,"api",false);    

    }
    public function setOutputPath($outputPath) {
        $this->outputPath = $outputPath; 
    }
    private function generateStructure() {
        $filePath = realpath(__DIR__."/../xslt/structure.xsl");
        $xml = new  DOMDocument("1.0","UTF-8");
        $xml->load($this->wsdl);
        
        $xsl = new DOMDocument("1.0","UTF-8");
        $xsl->load($filePath);
        $proc = new XSLTProcessor;
        $proc->importStyleSheet($xsl);
        $this->setXsltParams($proc);

       return  $proc->transformToXml($xml);
    }
    private function generateCode($xmlString,$dir,$replace) {
        echo "\ngenerate $dir\n";
        if(!file_exists($this->outputPath)) {
            mkdir($this->outputPath,077,true);   
        }
        $fullPath = $this->outputPath."/".$dir."/";
        if(!file_exists($fullPath)) {
            mkdir($fullPath,077,true);   
        }
        $filePath = realpath(__DIR__."/../xslt/".$this->lang."-".$dir.".xsl");
        if(!file_exists($filePath)) {
            throw new Exception("Could not load XSLT: ". $filePath."\n");
        }
        $xsl = new DOMDocument("1.0","UTF-8");
        $xsl->load($filePath);
        $proc = new XSLTProcessor;
        $proc->importStyleSheet($xsl);
        $this->setXsltParams($proc);

        $xml = new  DOMDocument("1.0","UTF-8");
        $xml->loadXML($xmlString);   
        foreach($xml->firstChild->childNodes as $key => $child) {
            /**
             * @var DOMElement $child
             */
            if(get_class($child)=="DOMElement") {
                $childDoc  = new  DOMDocument("1.0","UTF-8");
                $childDoc->appendChild($childDoc->importNode($child,true));  
                $proc = new XSLTProcessor;
                $proc->importStyleSheet($xsl);
                $this->setXsltParams($proc);     
                $fileName = $fullPath.$child->getAttribute("name").".php";
                if(file_exists($fileName) && $replace == false){
                    echo "Existing ".$fileName ." was not overwritten\n"; 
                    continue;
                }
                $proc->transformToUri($childDoc,$fileName);
                //echo $this->outputPath."/".$dir."/".$child->getAttribute("name").".php" ."\n";
            }            
        }
        return;       
    }
    private function setXsltParams(XSLTProcessor $proc) {
        $proc->setParameter('','config-file',$this->configFile);
        $proc->setParameter('','api-name',$this->apiName);
        
    }
}
/*
$path= realpath(__DIR__."..");
echo "v2\n";
$xsltWsdlGenerator = new XsltWsdlGenerator("Ascio v2","v2","https://aws.ascio.com/2012/01/01/AscioService.xml");
$xsltWsdlGenerator->setCodeLang("php");
$xsltWsdlGenerator->setOutputPath($path."v2");
$xsltWsdlGenerator->generate();
die();
echo "v3\n";
$xsltWsdlGenerator = new XsltWsdlGenerator("Ascio v3","v3","https://aws.ascio.com/v3/aws.wsdl");
$xsltWsdlGenerator->setCodeLang("php");
$xsltWsdlGenerator->setOutputPath($path."v3");
$xsltWsdlGenerator->generate();
echo "dns\n";
$xsltWsdlGenerator = new XsltWsdlGenerator("AscioDNS ","dns","https://dnsservice.ascio.com/2010/10/30/DnsService.wsdl");
$xsltWsdlGenerator->setCodeLang("php");
$xsltWsdlGenerator->setOutputPath($path."dns");
$xsltWsdlGenerator->generate();

*/