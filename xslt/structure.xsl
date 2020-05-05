<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/"
    xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/" xmlns:xsd="http://www.w3.org/2001/XMLSchema"
    xmlns:lib="http://ascio.com/lib" exclude-result-prefixes="xs wsdl soap" version="1.0">
    <xsl:key name="operation-output" match="//wsdl:operation"
        use="substring-after(wsdl:output/@message, ':')"/>
    <xsl:key name="operation-input" match="//wsdl:operation"
        use="substring-after(wsdl:input/@message, ':')"/>
    <xsl:key name="operation" match="//wsdl:operation" use="@name"/>
    <xsl:key name="message-part" match="//wsdl:message"
        use="substring-after(wsdl:part/@element, ':')"/>
    <xsl:key name="message-name" match="//wsdl:message" use="@name"/>
    <xsl:key name="types" match="//xsd:schema/xsd:complexType | //xsd:schema/xsd:simpleType"
        use="@name"/>
    <xsl:param name="config-file"/>
    <xsl:variable name="config" select="document(concat('../config/', $config-file, '.xml'))"/>
    <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz'"/>
    <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>
    <xsl:param name="api-name" select="'Ascio V2'"/>
    <xsl:output indent="yes"/>
    <xsl:template match="/">
        <classes>
            <xsl:apply-templates select="//wsdl:portType"/>
            <xsl:apply-templates select="//xsd:schema/xsd:complexType[@name]"/>
            <xsl:apply-templates select="//xsd:schema//xsd:element[xsd:complexType and @name and not(key('types', @name))]"/>
            <xsl:apply-templates select="//xsd:schema/xsd:simpleType"/>
            
        </classes>
    </xsl:template>
    <!-- Service Class -->
    <xsl:template match="wsdl:portType">
        <class name="Service" extends="ServiceBase">
            <classmap>
                <xsl:apply-templates select="//xsd:schema/xsd:complexType[@name]" mode="classmap"/>
                <xsl:apply-templates  select="//xsd:schema/xsd:element[@name and not(key('types', @name))]" mode="classmap"/>
                <xsl:apply-templates  select="//xsd:schema//xsd:element[xsd:complexType and @name and not(key('types', @name))]" mode="classmap"/>
                <xsl:apply-templates select="//xsd:schema/xsd:simpleType" mode="classmap"/>
            </classmap>
            <xsl:apply-templates select="//wsdl:portType/wsdl:operation"/>
        </class>
    </xsl:template>
    <!-- Classmap -->
    <xsl:template match="*" mode="classmap">
        <map><xsl:value-of select="@name"/></map>
    </xsl:template>
    <!-- Service-Method -->
    <xsl:template match="wsdl:operation">
        <xsl:variable name="method-name" select="concat(substring(translate(@name,$uppercase,$lowercase),1,1),substring(@name,2))"/>
        <xsl:variable name="name" select="@name"/>
        <xsl:variable name="message"
            select="substring-after(key('operation', @name)/wsdl:output/@message, ':')"/>
        <method name="{@name}" method-name="{$method-name}">
            <return>
                <xsl:value-of
                    select="substring-after(key('message-name', $message)/wsdl:part/@element, ':')"
                />
            </return>
            <xsl:apply-templates mode="signature" select="//xsd:schema/xsd:element[@name = $name]"/>
        </method>
    </xsl:template>
    <!-- Service Method Argument -->
    <xsl:template match="xsd:element" mode="signature">
        <xsl:for-each select="xsd:complexType/xsd:sequence/xsd:element">
            <xsl:variable name="type" select="substring-after(@type,':')"/>
            <xsl:variable name="type-node" select="local-name(key('types',$type))"/>           
            <argument name="{@name}"  type="{$type}">
                <xsl:if test="$type-node='simpleType'">
                    <xsl:attribute name="const">true</xsl:attribute>
                </xsl:if>
            </argument>
        </xsl:for-each>
    </xsl:template>
    <!-- Class -->
    <xsl:template match="xsd:element[@name] | xsd:complexType[@name]">        
        <xsl:variable name="is-array" select="xsd:sequence[count(xsd:element) = 1]/xsd:element[@maxOccurs = 'unbounded']"/>
        <xsl:variable name="name" select="@name"/>  
        <xsl:variable name="type" select="substring-after(xsd:complexContent/xsd:extension/@base,':')"/>
        <class name="{@name}">
            <xsl:if test="key('types',$type)">                
                <xsl:attribute name="inherited">true</xsl:attribute>            
            </xsl:if>
            <xsl:if test="$config//db/used-classes/class[. = $name]">
                <xsl:attribute name="has-db">true</xsl:attribute>
            </xsl:if>
            <xsl:if test="$config//api/used-classes/class[. = $name]">
                <xsl:attribute name="has-api">true</xsl:attribute>
            </xsl:if>
            <xsl:if test="$is-array">
                <xsl:attribute name="array">true</xsl:attribute>
            </xsl:if>
            <xsl:call-template name="get-extend"/>
            <xsl:call-template name="lib-extend"/>
            <xsl:call-template name="get-substitutions"/>
            <xsl:call-template name="is-substitued"/>
            <properties>               
                <xsl:apply-templates select="descendant::xsd:sequence[1]" mode="property">
                    <xsl:with-param name="class" select="."></xsl:with-param>
                </xsl:apply-templates>                 
            </properties>
        </class>
    </xsl:template>
    <xsl:template match="xsd:sequence" mode="property">
        <xsl:param name="class"/>
        <xsl:param name="inherited"/>
        <xsl:variable name="type" select="substring-after($class/xsd:complexContent/xsd:extension/@base,':')"/>
        <xsl:variable name="inherited-class" select="key('types',$type)"/>
        <xsl:apply-templates select="$inherited-class/descendant::xsd:sequence[1]" mode="property">
            <xsl:with-param name="inherited">true</xsl:with-param>
            <xsl:with-param name="class" select="$inherited-class"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="xsd:element" mode="property">
            <xsl:with-param name="class-name" select="$class/@name"/>
            <xsl:with-param name="class" select="$class"/>
            <xsl:with-param name="inherited" select="$inherited"></xsl:with-param>
        </xsl:apply-templates>
    </xsl:template>
    <xsl:template name="get-substitutions">
        <xsl:variable name="name" select="@name"/>
        <xsl:variable name="substitutions" select="//xsd:complexType/xsd:complexContent/xsd:extension[substring-after(@base,':')=$name]/../.."/>
        <xsl:if test="$substitutions">
            <substitutions>
                <xsl:for-each select="$substitutions">
                    <substitution><xsl:value-of select="@name"/></substitution>         
                </xsl:for-each>    
            </substitutions>            
        </xsl:if>
    </xsl:template>
    <xsl:template name="is-substitued">
        <xsl:variable name="type" select="key('types',substring-after(xsd:complexContent/xsd:extension/@base,':'))"/>
        <xsl:if test="$type/@abstract=true()">
            <xsl:attribute name="substituted">true</xsl:attribute>
        </xsl:if>
    </xsl:template>
    <!-- Property -->
    <xsl:template match="xsd:element" mode="property">
        <xsl:param name="class-name"/>
        <xsl:param name="class"/>
        <xsl:param name="inherited"/>
        <xsl:variable name="get-set-name"
            select="concat(translate(substring(@name, 1, 1), $lowercase, $uppercase), substring(@name, 2))"/>
        <xsl:variable name="type">
            <xsl:choose>
                <xsl:when test="contains(@type, 'dateTime')">DateTime</xsl:when>
                <xsl:when test="@type">
                    <xsl:value-of select="substring-after(@type, ':')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@name"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>       
        <property name="{@name}" type="{$type}" get-set-name="{$get-set-name}" var="{@name}">
            <xsl:if test="$inherited=true()">
                <xsl:attribute name="inherited">true</xsl:attribute>
            </xsl:if>
            <xsl:if test="
                contains(@type, ':string') or
                contains(@type, ':decimal') or
                contains(@type, ':int') or
                contains(@type, ':integer') or
                contains(@type, ':boolean') or
                contains(@type, ':base64') or
                contains(@type, ':date') or
                contains(@type, ':time') or
                contains(@type, ':long') or
                contains(@type, ':short') or
                contains(@type, ':dateTime')">
                <xsl:attribute name="native-type">true</xsl:attribute>
            </xsl:if>
            <xsl:if test="//xsd:schema/xsd:simpleType[@name=$type]">
                <xsl:attribute name="const">true</xsl:attribute>
                <xsl:attribute name="native-type">true</xsl:attribute>
            </xsl:if>
            <xsl:if test="@maxOccurs='unbounded'">
                <xsl:attribute name="array-item">true</xsl:attribute>
            </xsl:if>
            <xsl:variable name="name" select="@name"/>
            <xsl:if test="$config//ids/id=$name">
                <xsl:attribute name="is-handle">true</xsl:attribute>
            </xsl:if>
            <!-- child properties -->
            <xsl:apply-templates select="descendant::xsd:element" mode="property">
                <xsl:with-param name="class" select="."/>
                <xsl:with-param name="class-name" select="@name"/>
            </xsl:apply-templates>                        
        </property>
    </xsl:template>
    <!-- @extend -->
    <xsl:template name="get-extend">
        <xsl:variable name="name" select="@name"/>
        <xsl:variable name="out-message" select="key('message-part', @name)"/>
        <xsl:variable name="in-message" select="key('message-part', @name)"/>
        <xsl:variable name="is-array" select="xsd:sequence[count(xsd:element) = 1]/xsd:element[@maxOccurs = 'unbounded']"/>
        <xsl:attribute name="extends">            
            <xsl:choose>
                <!-- Simple Type -->
                <xsl:when test="local-name(.) = 'simpleType'">false</xsl:when>
                <!-- XSD Type -->
                <xsl:when test="xsd:complexContent/xsd:extension/@base">
                    <xsl:value-of
                        select="substring-after(xsd:complexContent/xsd:extension/@base, ':')"/>
                </xsl:when>
                <!-- DB -->
                <xsl:when test="$config//db/used-classes/class[.=$name] and $is-array">
                    <xsl:text>DbArrayBase</xsl:text>
                </xsl:when>
                <!-- DB -->
                <xsl:when test="$config//db/used-classes/class[.=$name]">
                    <xsl:text>DbBase</xsl:text>
                </xsl:when>
                <!-- Response Root -->
                <xsl:when test="key('operation-output', $out-message/@name)/@name"
                    >ResponseRootElement</xsl:when>
                <!-- Request Root -->
                <xsl:when test="key('operation-input', $in-message/@name)/@name"
                    >RequestRootElement</xsl:when>
                <!-- Array -->
                <xsl:when
                    test="$is-array"
                    >ArrayBase</xsl:when>
                <!-- Base -->
                <xsl:otherwise>Base</xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
    </xsl:template>
    <xsl:template name="is-handle">
        <xsl:variable name="name" select="@name"/>
        <xsl:if test="$config//ids/id=$name">
            <xsl:attribute name="is-handle">true</xsl:attribute>
        </xsl:if>
    </xsl:template>
    <xsl:template name="lib-extend">
        <xsl:if test="xsd:complexContent/xsd:extension/@base">
            <xsl:attribute name="lib-extend">true</xsl:attribute>
        </xsl:if>        
    </xsl:template>
    <!-- Const -->
    <xsl:template match="xsd:simpleType">
        <class name="{@name}">
            <xsl:apply-templates select="xsd:restriction/xsd:enumeration"/>
        </class>
    </xsl:template>
    <xsl:template match="xsd:enumeration">
        <const name="{@value}"/>
    </xsl:template>
</xsl:stylesheet>
