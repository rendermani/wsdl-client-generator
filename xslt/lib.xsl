<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="1.0">
    <xsl:param name="config-file"/>
    <xsl:variable name="config" select="document(concat('../config/', $config-file, '.xml'))"/>
    <xsl:template name="replace-string">
        <xsl:param name="text"/>
        <xsl:param name="replace"/>
        <xsl:param name="with"/>
        <xsl:choose>
            <xsl:when test="contains($text,$replace)">
                <xsl:value-of select="substring-before($text,$replace)"/>
                <xsl:value-of select="$with"/>
                <xsl:call-template name="replace-string">
                    <xsl:with-param name="text"
                        select="substring-after($text,$replace)"/>
                    <xsl:with-param name="replace" select="$replace"/>
                    <xsl:with-param name="with" select="$with"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$text"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template name="construct-function">
        <xsl:param name="function"></xsl:param>
        <xsl:text>&#9;function __construct($parent) {&#10;</xsl:text>
        <xsl:value-of select="concat('&#9;&#9;$this->client = Ascio::getClient(&quot;',$config//api-name,'&quot;);&#10;')"/>
        <xsl:text>&#9;&#9;$this->parent = $parent;&#10;</xsl:text>
        <xsl:text>&#9;}&#10;</xsl:text>
    </xsl:template>
    <xsl:template name="rest-function">
        <xsl:param name="function"></xsl:param>
        <xsl:param name="arg"></xsl:param>
        <xsl:value-of select="concat('&#9;function ',$function,'($',$arg,'=null) {&#10;')"/>
        <xsl:text>&#9;&#9;throw new \ascio\lib\AscioException("Not implemented yet.");&#10;</xsl:text>
        <xsl:text>&#9;}&#10;</xsl:text>
    </xsl:template>
</xsl:stylesheet>