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
            <xsl:with-param name="text" select="$config/config/namespace"/>
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
                <xsl:text>implements Iterator </xsl:text>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="uri" select="concat($config//output-dir, '/', @name, '.php')"/>
        <xsl:call-template name="header"/>
        <xsl:value-of select="concat('&#10;namespace ', $config//namespace, ';&#10;')"/>
        <xsl:text>&#10;</xsl:text>
        <xsl:value-of select="concat('&#10;class ', @name, $extends,$implements, ' {&#10;')"/>
        <xsl:apply-templates select="classmap"/>
        <xsl:apply-templates select="properties" mode="list"></xsl:apply-templates>
        <xsl:apply-templates select="properties/property" mode="def"/>
        <xsl:text>&#10;&#10;</xsl:text>
        <xsl:apply-templates select="const | properties/property | method"/>
        <xsl:text>}</xsl:text>
    </xsl:template>
    <!-- classmap -->
    <xsl:template match="classmap">
        <xsl:text>&#9;private static $classmap = [&#10;</xsl:text>
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
        <xsl:value-of select="concat('&#9;&#9;&#34;', ., '&#34; => &#34;', $class, '&#34;,&#10;')"/>
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
        <xsl:value-of select="concat('&#34;', @name, '&#34;')"/>
        <xsl:if test="not(position()=last())">, </xsl:if>        
    </xsl:template>
    <!-- property def -->
    <xsl:template match="property" mode="def">
        <xsl:text>&#10;</xsl:text>
        <xsl:value-of select="concat('&#9;protected $', @name, ';')"/>
    </xsl:template>
    <!-- property setter and getter -->
    <xsl:template match="property">
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
                <xsl:when test="@native-type=true()">
                    <xsl:value-of select="@type"/>
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
                <xsl:when test="$array">Iterator</xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$escaped-type"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="type-string" select="concat(' &#34;', $escaped-type, '&#34;')"/>
        <xsl:variable name="set"
            select="concat('&#9;public function set', @get-set-name, ' (', $type, ' $', @var, ') : ', $class, ' {&#10;')"/>
        <xsl:variable name="get"
            select="concat('&#9;public function get', @get-set-name, ' () : ', $type, ' {&#10;')"/>
        <xsl:variable name="setContent"
            select="concat('&#9;&#9;$this->setProperty(&#34;', @name, '&#34;, $', @var, ',', $type-string, ');&#10;&#9;&#9;return $this;&#10;')"/>
        <xsl:variable name="getContent"
            select="concat('&#9;&#9;return $this->get',$array,'Property(&#34;', @name, '&#34;,', $type-string, ');&#10;')"/>
        <xsl:value-of select="concat($set, $setContent, '&#9;}&#10;')"/>
        <xsl:value-of select="concat($get, $getContent, '&#9;}&#10;')"/>
    </xsl:template>
    <!-- const -->
    <xsl:template match="const">
        <xsl:value-of select="concat('&#9;const ', @name, ' = &#34;', @name, '&#34;;&#10;')"/>
    </xsl:template>
    <xsl:template match="@extends">
        <xsl:variable name="namespace" select="$config//lib/namespace"/>
        <xsl:value-of select="concat(' extends ', $namespace,'\',., ' ')"/>
    </xsl:template>
    <!-- soap-client-method -->
    <xsl:template match="method">
        <xsl:variable name="arguments">
            <xsl:for-each select="argument[not(@name = 'sessionId')]">
                <xsl:if test="not(position() = 1)">, </xsl:if>
                <xsl:value-of select="concat(@type, ' $', @name)"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="call-arguments">
            <xsl:for-each select="argument[not(@name = 'sessionId')]">
                <xsl:if test="not(position() = 1)">, </xsl:if>
                <xsl:value-of select="concat('[&quot;',@name,'&quot; => $',@name,']')"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="spacer">
            <xsl:if test="not($arguments = '')">
                <xsl:text>, </xsl:text>
            </xsl:if>
        </xsl:variable>
        <xsl:value-of select="concat('&#9;public function ', @name, '(')"/>
        <xsl:value-of select="$arguments"/>
        <xsl:text>) </xsl:text>
        <xsl:value-of select="concat(': ', ./return)"/>
        <xsl:text> {&#10;</xsl:text>
        <xsl:value-of
            select="concat('&#9;&#9;return $this->call(&#34;', @name, '&#34;', $spacer, $call-arguments, ');&#10;')"/>
        <xsl:text>&#9;}&#10;</xsl:text>
    </xsl:template>
    <!-- header -->
    <xsl:template name="header">
        <xsl:text>&lt;?php&#10;&#10;// XSLT-WSDL-Client. Generated PHP class of </xsl:text>
        <xsl:value-of select="@name"/>
        <xsl:text>&#10;</xsl:text>
    </xsl:template>
</xsl:stylesheet>
