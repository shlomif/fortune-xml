<?xml version="1.0" encoding="utf-8" ?>
<xsl:stylesheet version = '1.0'
    xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
    
     >

<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"
 doctype-public="-//W3C//DTD XHTML 1.1//EN"
 doctype-system="http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"
 />

<xsl:template match="/collection">
    <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en-US">
        <head>
            <title>Fortunes</title>
            <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
        </head>
        <body>
            <xsl:apply-templates select="list/fortune" />
        </body>
    </html>
</xsl:template>

<xsl:template match="fortune">
    <div xmlns="http://www.w3.org/1999/xhtml" class="fortune">
        <h3 id="{@id}"><xsl:call-template name="get_header" /></h3>
        <table class="irc-conversation">
            <tbody>
                <xsl:apply-templates select="irc/body"/>
            </tbody>
        </table>
    </div>
</xsl:template>

<xsl:template match="body">
    <xsl:apply-templates select="saying|me_is|joins|leaves" />
</xsl:template>

<xsl:template match="saying|me_is|joins|leaves">
    <tr xmlns="http://www.w3.org/1999/xhtml">
        <xsl:attribute name="class">
            <xsl:value-of select="name(.)" />
        </xsl:attribute>
        <td class="who">
            <xsl:choose>
                <xsl:when test="name(.) = 'me_is'">
                    <xsl:text>* </xsl:text>
                </xsl:when>
                <xsl:when test="name(.) = 'joins'">
                    <xsl:text>←</xsl:text>
                </xsl:when>
                <xsl:when test="name(.) = 'leaves'">
                    <xsl:text>→</xsl:text>
                </xsl:when>
            </xsl:choose> 
            <xsl:value-of select="@who" />
        </td>        
        <td class="text">
            <xsl:value-of select="." />
        </td>
    </tr>
</xsl:template>

<xsl:template name="get_irc_default_header">
    <xsl:choose>
        <xsl:when test="info">
            <xsl:if test="info/tagline">
                <xsl:value-of select="info/tagline" /> on
            </xsl:if>
            <xsl:if test="info/network">
                <xsl:value-of select="info/network" />'s
            </xsl:if>
            <xsl:value-of select="info/channel" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>Unknown Subject</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="get_header">
    <xsl:choose>
        <xsl:when test="meta/title">
            <xsl:value-of select="meta/title" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:call-template name="get_irc_default_header" select="irc" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

</xsl:stylesheet>
