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
            <xsl:apply-templates select="class[@name=$config//db/used-classes/class] | classes/class[@name=$config//db/used-classes/class]"/>        
    </xsl:template>
    <!-- create class -->
    <xsl:template match="class">
        <xsl:param name="name"/>
        <xsl:variable name="extends">
           <xsl:value-of select="$config//db/class"/>
        </xsl:variable>
        <xsl:call-template name="header"/>
        <xsl:value-of select="concat('&#10;namespace ', $config//db/namespace, ';&#10;')"/>
        <xsl:text>&#10;</xsl:text>
        <xsl:value-of select="concat('&#10;class ', @name,'Db extends ', $extends, ' {&#10;')"/>
        <xsl:text>&#10;</xsl:text>
        <xsl:text>&#9;public $parent;&#10;</xsl:text>
        <xsl:text>&#9;public $client;&#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
        <xsl:call-template name="construct-function"></xsl:call-template>
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
        <xsl:text>&#10;&#10;</xsl:text>
        <xsl:text>}</xsl:text>
    </xsl:template>
    <xsl:template match="@extends">
        <xsl:variable name="namespace" select="$config//lib/namespace"/>
        <xsl:value-of select="concat(' extends ', $namespace,'\',., ' ')"/>
    </xsl:template>
    <!-- header -->
    <xsl:template name="header">
        <xsl:text>&lt;?php&#10;&#10;// XSLT-WSDL-Client. Generated DB-Model class of </xsl:text>
        <xsl:value-of select="@name"/>
        <xsl:text>. Can be copied and overwriten with own functions.&#10;</xsl:text>
    </xsl:template>
</xsl:stylesheet>
