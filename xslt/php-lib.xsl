<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsd="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs" version="1.0">
    <xsl:import href="lib.xsl"/>
    <xsl:param name="config-file"/>
    <xsl:output method="text"/>
    <xsl:variable name="config" select="document($config-file)"/>
    <xsl:variable name="escaped-ns">
        <xsl:call-template name="replace-string">
            <xsl:with-param name="text" select="$config/config/namespace"/>
            <xsl:with-param name="replace" select="'\'"/>
            <xsl:with-param name="with" select="'\\'"/>
        </xsl:call-template>
    </xsl:variable>
    <xsl:template match="/">
        <xsl:apply-templates select="class | classes/class"/>
    </xsl:template>
    <!-- create class -->
    <xsl:template match="class">        
        <xsl:param name="name"/>
        <xsl:variable name="extends">
            <xsl:value-of select="concat('\',$config/config/namespace,'\',@name)"/>
        </xsl:variable>        
        <xsl:call-template name="header"/>        
        <xsl:value-of select="concat('&#10;namespace ', $config//lib/namespace, ';&#10;')"/>
        <xsl:apply-templates select="@has-db" mode="use-ns"/>
        <xsl:apply-templates select="@has-api" mode="use-ns"/>
        <xsl:value-of select="concat('&#10;class ', @name,' extends ', $extends, ' {&#10;')"/>               
        <xsl:text>}</xsl:text>
    </xsl:template>
    <xsl:template match="@extends">
        <xsl:value-of select="concat(' extends ', ., ' ')"/>
    </xsl:template>
    <!-- db -->
    <xsl:template match="@has-db" mode="def">
        <xsl:text>&#9;protected $_db;&#10;</xsl:text>
    </xsl:template>
    <xsl:template match="@has-db">
        <xsl:value-of select="concat('&#9;&#9;$this->_db = new ',../@name,'Db($this);&#10;')"/>
    </xsl:template>
    <xsl:template match="@has-db" mode="use-ns">
        <xsl:value-of select="concat('use ',$config//db/namespace,'\',../@name,'Db;&#10;')"/>
    </xsl:template>
    <!-- api -->
    <xsl:template match="@has-api" mode="def">
        <xsl:text>&#9;protected $_api;&#10;</xsl:text>
    </xsl:template>
    <xsl:template match="@has-api">
        <xsl:value-of select="concat('&#9;&#9;$this->_api = new ',../@name,'Api($this);&#10;')"/>
    </xsl:template>
    <xsl:template match="@has-api" mode="use-ns">
        <xsl:value-of select="concat('use ',$config//api/namespace,'\',../@name,'Api;&#10;')"/>
    </xsl:template>
    <xsl:template name="constructor">
        <xsl:apply-templates select="@has-db" mode="def"/>
        <xsl:apply-templates select="@has-api" mode="def"/>
        <xsl:text>&#10;&#9;public function __construct() {&#10;</xsl:text>
        <xsl:apply-templates select="@has-db"/>
        <xsl:apply-templates select="@has-api"/>
        <xsl:text>&#9;}</xsl:text>
    </xsl:template>
    <!-- header -->
    <xsl:template name="header">
        <xsl:text>&lt;?php&#10;&#10;// XSLT-WSDL-Client. Generated DB-Model class of </xsl:text>
        <xsl:value-of select="@name"/>
        <xsl:text>. Can be copied and overwriten with own functions.&#10;</xsl:text>
    </xsl:template>
    
</xsl:stylesheet>
