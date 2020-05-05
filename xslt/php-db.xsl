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
            <xsl:choose>
                <xsl:when test="@lib-extend=true()">
                    <xsl:value-of select="concat(@extends,'Db')"/>
                </xsl:when>
                <xsl:when test="@array=true()">
                    <xsl:value-of select="$config//db/array-class"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$config//db/class"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>            
        <xsl:variable name="table">
            <xsl:choose>
                <xsl:when test="@substituted = true()">
                    <xsl:value-of select="concat($config//api-name,'_',@extends)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat($config//api-name,'_',@name)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:call-template name="header"/>
        <xsl:value-of select="concat('&#10;namespace ', $config//db/namespace, ';&#10;')"/>
        <xsl:if test="not(@lib-extend)">
            <xsl:value-of select="concat('use ', $config//base/namespace,'\',$extends, ';&#10;')"/>     
        </xsl:if>           
        <xsl:text>&#10;</xsl:text>
        <xsl:value-of select="concat('&#10;class ', @name,'Db extends ', $extends, ' {&#10;')"/>
        <xsl:value-of select="concat('&#9;protected $table=&quot;',$table,'&quot;;&#10;')"/>
        <xsl:apply-templates select="properties/property[not(@native-type=true())]" mode="db-relation"></xsl:apply-templates>
        <xsl:text>&#10;</xsl:text>
        <xsl:text>}</xsl:text>
    </xsl:template>
    <!-- header -->
    <xsl:template match="property" mode="db-relation">         
        <xsl:text>&#9;</xsl:text>
        <xsl:value-of select="concat('public function get',@name,'(){&#10;')"></xsl:value-of>
        <xsl:text>&#9;&#9;</xsl:text>        
        <xsl:value-of select="concat('return $this->getRelationObject(&quot;',$config//api-name,'&quot;,&quot;',@type,'&quot;,','&quot;',@name,'&quot;);')"/>
        <xsl:text>&#10;&#9;}&#10;</xsl:text>
    </xsl:template>   
    <xsl:template name="header">
        <xsl:text>&lt;?php&#10;&#10;// XSLT-WSDL-Client. Generated DB-Model class of </xsl:text>
        <xsl:value-of select="@name"/>
        <xsl:text>. Can be copied and overwriten with own functions.&#10;</xsl:text>
    </xsl:template>
</xsl:stylesheet>
