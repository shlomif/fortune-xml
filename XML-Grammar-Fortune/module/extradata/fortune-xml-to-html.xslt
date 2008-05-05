<xsl:stylesheet version = '1.0'
     xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
     >

<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"
 doctype-public="-//W3C//DTD XHTML 1.1//EN"
 doctype-system="http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"
 />

<xsl:template match="/">
    <html>
        <head><title>Fortunes</title></head>
        <body>
            <xsl:apply-templates select="list/fortune" />
        </body>
    </html>
</xsl:template>

<xsl:template match="fortune">
    <div class="fortune">
        <h3 id="{@id}"><xsl:call-template name="get_irc_header" /></h3>
        <table class="irc-conversation">
            <tbody>
                <xsl:apply-templates select="irc/body"/>
            </tbody>
        </table>
    </div>
</xsl:template>

<xsl:template match="body">
    <xsl:apply-template select="saying|me_is|joins|leaves" />
</xsl:template>

<xsl:template match="saying|me_is|joins|leaves">
    <tr>
        <xsl:attribute name="class">
            <xsl:value-of select="name(.)" />
        </xsl:attribute>
        <td class="who">
            <xsl:choose>
                <xsl:when test="name(.) = 'me_is'">
                    <xsl:text>* </xsl:text>
                </xsl:when>
                <xsl:when test="name(.) = 'joins'">
                    <xsl:text>&larr;</xsl:text>
                </xsl:when>
                <xsl:when test="name(.) = 'leaves'">
                    <xsl:text>&rarr;</xsl:text>
                </xsl:when>
            </xsl:choose> 
            <xsl:value-of "@who" />
        </td>        
        <td class="text">
            <xsl:value-of "." />
        </td>
    </tr>
</xsl:template>

<xsl:template name="get_irc_header">
    <xsl:if test="info/tagline">
        <xsl:value-of select="info/tagline" /> on
    </xsl:if>
    <xsl:if test="info/network">
        <xsl:value-of select="info/network" />'s
    </xsl:if>
    <xsl:value-of select="info/channel" />
</xsl:template>

</xsl:stylesheet>
