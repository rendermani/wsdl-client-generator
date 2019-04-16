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
        <xsl:apply-templates select="class[@name=$config//api/used-classes/class] | classes/class[@name=$config//api/used-classes/class]"/>
    </xsl:template>
    <!-- create class -->
    <xsl:template match="class">
        <xsl:param name="name"/>
        <xsl:variable name="extends">
           <xsl:value-of select="$config//api/class"/>
        </xsl:variable>
        <xsl:call-template name="header"/>
        <xsl:value-of select="concat('&#10;namespace ', $config//api/namespace, ';&#10;')"/>
        <xsl:text>&#10;</xsl:text>
        <xsl:value-of select="concat('&#10;class ', @name,'Api extends ', $extends, ' {&#10;')"/>
        <xsl:text>&#10;</xsl:text>
        <xsl:call-template name="id"></xsl:call-template>
        <xsl:text>&#9;public $parent;&#10;</xsl:text>
        <xsl:text>&#9;public $client;</xsl:text>
        <xsl:apply-templates select="properties" mode="list"></xsl:apply-templates>        
        <xsl:text>&#10;&#10;</xsl:text>        
        <xsl:call-template name="rest-function">
            <xsl:with-param name="function">create</xsl:with-param>
        </xsl:call-template>
        <xsl:call-template name="rest-function">
            <xsl:with-param name="function">update</xsl:with-param>
        </xsl:call-template>
        <xsl:call-template name="rest-function">
            <xsl:with-param name="function">delete</xsl:with-param>
        </xsl:call-template>
        <xsl:call-template name="rest-function">
            <xsl:with-param name="function">get</xsl:with-param>
        </xsl:call-template>        
        <xsl:text>}</xsl:text>
    </xsl:template>
    <xsl:template name="id">
        <xsl:variable name="class" select="."/>
        <xsl:variable name="id" select="$config//ids/id[.=$class//property/@name]"/>
        <xsl:if test="$id">
            <xsl:value-of select="concat('&#9;public const IdProperty=&quot;',$id,'&quot;;&#10;')"/>
        </xsl:if>
    </xsl:template>
    <!-- property list -->
    <xsl:template match="properties" mode="list">
        <xsl:text>&#10;&#9;protected $properties=[</xsl:text>
        <xsl:apply-templates mode="list" select="property"/>
        <xsl:text>];</xsl:text>
        <xsl:text>&#10;&#9;protected $objects=[</xsl:text>
        <xsl:apply-templates mode="list" select="property[not(@native-type=true())]"/>
        <xsl:text>];</xsl:text>
    </xsl:template>
    <xsl:template match="property" mode="list">        
        <xsl:value-of select="concat('&#34;', @name, '&#34;')"/>
        <xsl:if test="not(position()=last())">, </xsl:if>        
    </xsl:template>
    <!-- header -->
    <xsl:template name="header">
        <xsl:text>&lt;?php&#10;&#10;// XSLT-WSDL-Client. Generated DB-Model class of </xsl:text>
        <xsl:value-of select="@name"/>
        <xsl:text>. Can be copied and overwriten with own functions.&#10;</xsl:text>
    </xsl:template>
</xsl:stylesheet>
