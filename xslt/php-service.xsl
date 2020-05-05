<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsd="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs" version="1.0">
    <xsl:import href="lib.xsl"/>
    <xsl:param name="config-file"/>
    <xsl:output method="text"/>
    <xsl:variable name="config" select="document(concat('../config/', $config-file, '.xml'))"/>
    <xsl:variable name="escaped-ns">
        <xsl:call-template name="replace-string">
            <xsl:with-param name="text" select="$config/config/lib/namespace"/>
            <xsl:with-param name="replace" select="'\'"/>
            <xsl:with-param name="with" select="'\\'"/>
        </xsl:call-template>
    </xsl:variable>
    <xsl:template match="/">
        <xsl:apply-templates select="classes/class | class"/>
    </xsl:template>
    <!-- create class -->
    <xsl:template match="class">
        <xsl:param name="name"/>
        <xsl:variable name="extends">
            <xsl:apply-templates select="@extends"/>
        </xsl:variable>
        <xsl:variable name="implements">
            <xsl:if test="@extends='ArrayBase'">
                <xsl:text>implements \Iterator </xsl:text>
            </xsl:if>
        </xsl:variable>
        
        <xsl:variable name="uri" select="concat($config//output-dir, '/', @name, '.php')"/>
        <xsl:call-template name="header"/>
        <xsl:value-of select="concat('&#10;namespace ', $config//namespace, ';&#10;')"/>
        <xsl:call-template name="use"></xsl:call-template>   
        <xsl:text>&#10;</xsl:text>
        <xsl:value-of select="concat('&#10;class ', @name, $extends,$implements, ' {&#10;')"/>
        <xsl:apply-templates select="classmap"/>
        <xsl:apply-templates select="properties" mode="list"></xsl:apply-templates>
        <xsl:apply-templates select="substitutions"></xsl:apply-templates>
        <xsl:apply-templates select="@substituted"></xsl:apply-templates>
        <xsl:apply-templates select="properties/property" mode="def"/>        
        <xsl:text>&#10;&#10;</xsl:text>
        <xsl:call-template name="constructor"></xsl:call-template>
        <xsl:call-template name="api"/>
        <xsl:call-template name="db"/>        
        <xsl:apply-templates select="const | properties/property | method"/>
        <xsl:text>}</xsl:text>
    </xsl:template>
    <xsl:template match="@substituted">
        <xsl:text>&#10;&#9;protected $_substituted = true;</xsl:text>
    </xsl:template>
    <xsl:template name = "use">
        <xsl:variable name="ns">
            <xsl:choose>
                <xsl:when test="@lib-extend">
                    <xsl:value-of select="$config//lib/namespace"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$config//base/namespace"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:if test="not(const)">
            <xsl:value-of select="concat('use ',$ns,'\',@extends, ';&#10;')"/>
            <xsl:value-of select="concat('use ', $config//db/namespace,'\',@name, 'Db;&#10;')"/>
            <xsl:value-of select="concat('use ', $config//api/namespace,'\',@name, 'Api;&#10;')"/>
        </xsl:if>     
        <xsl:if test="@inherited='true'">
            <xsl:value-of select="concat('use ', $config//api/namespace,'\',@extends, 'Api;&#10;')"/>
        </xsl:if>
    </xsl:template>
    <!-- classmap -->
    <xsl:template match="classmap">
        <xsl:text>&#9;protected $classmap = [&#10;</xsl:text>
        <xsl:apply-templates select="map"/>
        <xsl:text>&#9;];&#10;</xsl:text>
    </xsl:template>
    <xsl:template match="map">
        <xsl:variable name="name" select="."/>
        <xsl:variable name="class">
            <xsl:variable name="map-to"
                select="$config/config/classmap/class[@name = $name]/@map-to-class"/>
            <xsl:choose>
                <xsl:when test="not($map-to)">
                    <xsl:value-of select="concat($escaped-ns, '\\', .)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="replace-string">
                        <xsl:with-param name="text" select="$map-to"/>
                        <xsl:with-param name="replace" select="'\'"/>
                        <xsl:with-param name="with" select="'\\'"/>
                    </xsl:call-template>
                </xsl:otherwise>

            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="concat('&#9;&#9;&quot;', ., '&quot; => &quot;', $class, '&quot;,&#10;')"/>
    </xsl:template>
    <!-- property list -->
    <xsl:template match="properties" mode="list">
        <xsl:text>&#10;&#9;protected $_apiProperties=[</xsl:text>
        <xsl:apply-templates mode="list" select="property"/>
        <xsl:text>];</xsl:text>
        <xsl:text>&#10;&#9;protected $_apiObjects=[</xsl:text>
        <xsl:apply-templates mode="list" select="property[not(@native-type=true())]"/>
        <xsl:text>];</xsl:text>
    </xsl:template>
    <xsl:template match="property" mode="list">        
        <xsl:value-of select="concat('&quot;', @name, '&quot;')"/>
        <xsl:if test="not(position()=last())">, </xsl:if>        
    </xsl:template>
    <!-- property def -->
    <xsl:template match="property" mode="def">
        <xsl:text>&#10;</xsl:text>
        <xsl:value-of select="concat('&#9;protected $', @name, ';')"/>
    </xsl:template>
    <!-- property setter and getter -->    
    <xsl:template match="property[not(@inherited)]">
        <xsl:variable name="class" select="../../@name"/>
        <xsl:variable name="t" select="@type"/>
        <xsl:variable name="custom-class" select="$config//class[@name = ($t)]/@map-to-class"/>
        <xsl:variable name="array">
            <xsl:if test="@array-item=true()">
                <xsl:text>Iterator</xsl:text>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="type">
            <xsl:choose>
                <xsl:when test="$custom-class">
                    <xsl:value-of select="concat('\',$custom-class)"/>
                </xsl:when>
                <xsl:when test="@const=true()">string</xsl:when>
                <xsl:when test="@type='string'">string</xsl:when>
                <xsl:when test="@type='short'">int</xsl:when>
                <xsl:when test="@type='int'">int</xsl:when>
                <xsl:when test="@type='integer'">int</xsl:when>
                <xsl:when test="@type='boolean'">bool</xsl:when>
                <xsl:when test="@native-type=true()">
                    <xsl:value-of select="concat('\',@type)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('\',$config//lib/namespace,'\',@type)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="escaped-type">
            <xsl:call-template name="replace-string">
                <xsl:with-param name="text" select="$type"/>
                <xsl:with-param name="replace" select="'\'"/>
                <xsl:with-param name="with" select="'\\'"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="return-type">
            <xsl:choose>
                <xsl:when test="@array-item=true()">Iterator</xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$escaped-type"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="signature-type">
            <xsl:choose>
                <xsl:when test="@array-item=true()">Iterable</xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$type"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="type-string" select="concat(' &quot;', $escaped-type, '&quot;')"/>
        <xsl:variable name="set"
            select="concat('&#9;public function set', @get-set-name, ' (?', $signature-type, ' $', @var, ' = null) : self {&#10;')"/>
        <xsl:variable name="setContent"
            select="concat('&#9;&#9;$this->set(&quot;', @name, '&quot;, $', @var, ');&#10;&#9;&#9;return $this;&#10;')"/>
              <xsl:variable name="create"
                  select="concat('&#9;public function create', @get-set-name, ' () : ', $type, ' {&#10;')"/>
        <xsl:variable name="createContent"
            select="concat('&#9;&#9;return $this->create (&quot;', @name, '&quot;,', $type-string, ');&#10;')"/>
        <xsl:variable name="get"
            select="concat('&#9;public function get', @get-set-name, ' () : ?', $signature-type, ' {&#10;')"/>        
        <xsl:variable name="getContent"
            select="concat('&#9;&#9;return $this->get(&quot;', @name, '&quot;,',$type-string,');&#10;')"/>
        <xsl:variable name="add-arguments">
            <xsl:for-each select="property">
                <xsl:if test="not(position()=1)">
                    <xsl:text>, </xsl:text>
                </xsl:if>     
                <xsl:value-of select="concat(@type,' $',@var)"/>    
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="add"
            select="concat('&#9;public function add', @get-set-name, ' (',$add-arguments,') : ', $type, ' {&#10;')"/>        
        <xsl:variable name="addContent"
            select="concat('&#9;&#9;return $this->add(&quot;',@name, '&quot;,&quot;',$escaped-type, '&quot;,func_get_args());&#10;')"/>
        <xsl:value-of select="concat($set, $setContent, '&#9;}&#10;')"/>
        <xsl:value-of select="concat($get, $getContent, '&#9;}&#10;')"/>
        <xsl:if test="@native-type=false()">
            <xsl:value-of select="concat($create, $createContent, '&#9;}&#10;')"/>    
        </xsl:if>
        <xsl:if test="@array-item=true()">
            <xsl:value-of select="concat($add, $addContent, '&#9;}&#10;')"/>    
        </xsl:if>
        
    </xsl:template>
    <!-- const -->
    <xsl:template match="const">
        <xsl:value-of select="concat('&#9;const ', @name, ' = &quot;', @name, '&quot;;&#10;')"/>
    </xsl:template>
    <xsl:template match="@extends">
        <xsl:value-of select="concat(' extends ', ., ' ')"/>
    </xsl:template>
    <!-- soap-client-method -->
    <xsl:template match="method">
        <xsl:variable name="arguments">
            <xsl:for-each select="argument[not(@name = 'sessionId')]">
                <xsl:variable name="type">
                    <xsl:choose>
                        <xsl:when test="@const=true()">string</xsl:when>
                        <xsl:otherwise><xsl:value-of select="@type"/></xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>

                <xsl:if test="not(position() = 1)">, </xsl:if>
                <xsl:value-of select="concat($type, ' $', @name)"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="call-arguments">
            <xsl:text>[</xsl:text>
            <xsl:for-each select="argument[not(@name = 'sessionId')]">
                <xsl:if test="not(position() = 1)">, </xsl:if>
                <xsl:value-of select="concat('&quot;',@name,'&quot; => $',@name)"/>                
            </xsl:for-each>
            <xsl:text>]</xsl:text>
        </xsl:variable>
        <xsl:variable name="spacer">
            <xsl:if test="not($arguments = '')">
                <xsl:text>, </xsl:text>
            </xsl:if>
        </xsl:variable>
        <xsl:value-of select="concat('&#9;public function ', @method-name, '(')"/>
        <xsl:value-of select="$arguments"/>
        <xsl:text>) </xsl:text>
        <xsl:value-of select="concat(': ', ./return)"/>
        <xsl:text> {&#10;</xsl:text>
        <xsl:value-of
            select="concat('&#9;&#9;return $this->call(&quot;', @name, '&quot;', $spacer, $call-arguments, ');&#10;')"/>
        <xsl:text>&#9;}&#10;</xsl:text>
    </xsl:template>
    <!-- header -->
    <xsl:template name="header">
        <xsl:text>&lt;?php&#10;&#10;// XSLT-WSDL-Client. Generated PHP class of </xsl:text>
        <xsl:value-of select="@name"/>
        <xsl:text>&#10;</xsl:text>
    </xsl:template>
    <xsl:template name="constructor">
        <xsl:if test="@extends='DbBase' or @extends='DbArrayBase' or @has-db=true()">     
            <xsl:text>&#9;public function __construct($parent = null) {&#10;</xsl:text>     
            <xsl:text>&#9;&#9;parent::__construct($parent);&#10;</xsl:text>
            <xsl:text>&#10;&#9;&#9;//set the database model&#10;</xsl:text>        
            <xsl:value-of select="concat('&#9;&#9;$db = new ',@name,'Db();&#10;')"/>        
            <xsl:text>&#9;&#9;$db->parent($this);&#10;</xsl:text>
            <xsl:text>&#9;&#9;$this->db($db);&#10;</xsl:text>
            <xsl:if test="@name = $config//api/used-classes/class">                     
                <xsl:text>&#10;&#9;&#9;//set the api model&#10;</xsl:text>
                <xsl:value-of select="concat('&#9;&#9;$api = new ',@name,'Api($this);&#10;')"/>
                <xsl:text>&#9;&#9;$api->parent($this);&#10;</xsl:text>
                <xsl:value-of select="concat('&#9;&#9;$api->config($this->config()->',$config//api-name,');&#10;')"></xsl:value-of>
                <xsl:text>&#9;&#9;$this->api($api);&#10;</xsl:text>       
                
            </xsl:if>              
            <xsl:text>&#9;}&#10;</xsl:text>
        </xsl:if>
        
    </xsl:template>
    <xsl:template name="api">
        <xsl:if test="@name = $config//api/used-classes/class">                       
            <text>&#9;/**&#10;</text>
            <text>&#9;* Provides API-Specific methods like update,create,delete.&#10;</text>
            <text>&#9;* @param @name|null $api&#10;</text>
            <xsl:value-of select="concat('&#9;* @return ',@name,'Api&#10;')"/>
            <text>&#9;*/&#10;</text>
            <xsl:text>&#9;public function api($api = null) {&#10;</xsl:text>            
            <xsl:text>&#9;&#9;if(!$api) {&#10;</xsl:text>
            <xsl:text>&#9;&#9;&#9;return $this->_api;&#10;</xsl:text>
            <xsl:text>&#9;&#9;}&#10;</xsl:text>
            <xsl:text>&#9;&#9;$this->_api = $api;&#10;</xsl:text>
            <xsl:text>&#9;&#9;return $api;&#10;</xsl:text>
            <xsl:text>&#9;}&#10;</xsl:text>            
        </xsl:if>
    </xsl:template>
    <xsl:template name="db">
        <xsl:if test="@has-db=true()">            
            <text>&#9;/**&#10;</text>
            <text>&#9;* Provides DB-Specific methods like update,create,delete.&#10;</text>
            <xsl:value-of select="concat('&#9;* @param ',@name,'Db|null $db&#10;')"/>
            <xsl:value-of select="concat('&#9;* @return ',@name,'Db&#10;')"/>
            <text>&#9;*/&#10;</text>
            <xsl:text>&#9;public function db($db = null) {&#10;</xsl:text>          
            <xsl:text>&#9;&#9;if(!$db) {&#10;</xsl:text>
            <xsl:text>&#9;&#9;&#9;return $this->_db;&#10;</xsl:text>
            <xsl:text>&#9;&#9;}&#10;</xsl:text>
            <xsl:text>&#9;&#9;$this->_db = $db;&#10;</xsl:text>
            <xsl:text>&#9;&#9;$this->_db->parent($this);&#10;</xsl:text>
            <xsl:text>&#9;&#9;return $db;&#10;</xsl:text>
            <xsl:text>&#9;}&#10;</xsl:text>            
        </xsl:if>       
    </xsl:template>
    <xsl:template match="substitutions">
        <xsl:text>&#10;&#9;protected $_substitutions = [&#10;</xsl:text>
        <xsl:apply-templates select="substitution"></xsl:apply-templates>
        <xsl:text>&#9;];&#10;</xsl:text>
    </xsl:template>
    <xsl:template match="substitution">
        <xsl:variable name="type">
            <xsl:call-template name="replace-string">
                <xsl:with-param name="text" select="concat('\',$config//lib/namespace,'\',.)"/>
                <xsl:with-param name="replace" select="'\'"/>
                <xsl:with-param name="with" select="'\\'"/>                
            </xsl:call-template>    
        </xsl:variable>
        <xsl:text>&#9;&#9;</xsl:text>
        
        <xsl:value-of select="concat('[&quot;name&quot; => &quot;',.,'&quot;,&quot;type&quot; => &quot;',$type,'&quot;]')"/>
        <xsl:if test="not(position()=last())"><xsl:text>,</xsl:text></xsl:if>
        <xsl:text> &#10;</xsl:text>
    </xsl:template>
    <xsl:template match="*"></xsl:template>
</xsl:stylesheet>
