<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="1.0">
    <xsl:template match="class">
        <main>
            <use ns="base" api-ns="true" name="DbBase"/>    
            <use ns="db" api-ns="base" name="{@type}Db"/>
            <use ns="api" api-ns="true" name="{@type}Api"/>  
            <class extends="{@type}" api="v2">        
                <substitutions>
                    <substitution>MarkOrderRequest</substitution>
                    <substitution>AutoInstallSslOrderRequest</substitution>
                    <substitution>SslCertificateOrderRequest</substitution>
                    <substitution>NameWatchOrderRequest</substitution>
                    <substitution>DefensiveOrderRequest</substitution>
                </substitutions>
                <properties>
                    <property name="_apiProperties">
                        <array>
                            <item>DomainHandle</item>
                            <item>DomainName</item>
                        </array>
                    </property>
                    <property name="_apiObjects">
                        <array>
                            <item>Registrant</item>
                            <item>AdminContact</item>
                        </array>
                    </property>
                </properties>
                <function name="__construct">
                    <arguments>
                        <argument type="BaseClass" ns="lib" var="{@var}" mandatory="false"></argument>
                    </arguments>
                    <content>
                        <line>$db = new <type/>Db();</line>
                        <line>$db->parent($this);</line>
                        <line>$this->db($db);</line>            
                        <comment>set the api model</comment>
                        <line>$api = new <type/>Api();</line>
                        <line>$api->parent($this);</line>
                        <line>$api->config($this->config()->api);</line>
                        <line>$this->api($api);</line>
                        <line>parent::__construct($parent);</line>
                    </content>
                </function>
                <function name="api" >
                    <arguments>
                        <argument type="string" var="api" default="null"></argument>
                        <argument type="string" var="value"></argument>
                    </arguments>
                    <content>
                        <line>if(!$api) {</line>
                        <line><tab/>return $this->_api;</line>
                        <line>}</line>
                        <line>$this->_api = $api;</line>
                        <line>return $api;</line>
                    </content>
                    <return type="{@var}Api"/>
                </function>    
                <properties>
                    <function name="set{@type}">
                        <arguments>
                            <argument type="{@type}" var="{@type}" mandatory="true"></argument>
                        </arguments>
                        <content>
                            <function-call name="$this->set{@type}">
                                <arguments>
                                    <argument type="string" var="name"></argument>
                                    <argument type="string" var="value"></argument>
                                </arguments>
                                <return type="{@var}" ns="lib"/>
                            </function-call>
                            <function-call name="$this->get{@type}">
                                <arguments>
                                    <argument type="string" var="name"></argument>
                                </arguments>
                                <return type="{@type}" mandatory="false"/>
                            </function-call>
                            <function-call name="$this->create{@type}">
                                <arguments>
                                    <argument type="string" var="type"></argument>
                                    <argument type="string" var="name"></argument>
                                </arguments>
                                <return type="{@type}" ns="lib"/>
                            </function-call>
                        </content>
                    </function>
                    <return type="{@var}"/>
                </properties>
            </class>
            
        </main>
    </xsl:template>
</xsl:stylesheet>