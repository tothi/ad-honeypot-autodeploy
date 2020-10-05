<?xml version="1.0" ?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output omit-xml-declaration="yes" indent="yes"/>

  <xsl:template match="node()|@*">
     <xsl:copy>
       <xsl:apply-templates select="node()|@*"/>
     </xsl:copy>
  </xsl:template>

  <xsl:template match="/network/ip/dhcp">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:copy-of select="node()"/>
      <host mac='50:73:0F:31:81:E1' ip='192.168.3.100'/>
      <host mac='50:73:0F:31:81:E2' ip='192.168.3.112'/>
      <host mac='50:73:0F:31:81:F1' ip='192.168.3.191'/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
