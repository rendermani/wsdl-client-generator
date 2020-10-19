<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="2.0">
    <xsl:output indent="yes"/>
    <xsl:template match="/">
        <classes>
            <xsl:apply-templates select="//class[properties]"></xsl:apply-templates>    
        </classes>
        
    </xsl:template>
    <xsl:template match="class">
        <class><xsl:value-of select="@name"/></class>
    </xsl:template>
</xsl:stylesheet>