<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:array="http://www.w3.org/2005/xpath-functions/array"
                xmlns:map="http://www.w3.org/2005/xpath-functions/map"
                xmlns:math="http://www.w3.org/2005/xpath-functions/math"
                xmlns:jt="foo"
                xmlns:html="http://www.w3.org/1999/xhtml"
                xpath-default-namespace="http://www.tei-c.org/ns/1.0"
                xmlns="http://www.tei-c.org/ns/1.0"
                exclude-result-prefixes="#all"
                expand-text="yes"
                version="3.0">

    <xsl:output method="xml" indent="yes"/>
    <xsl:mode on-no-match="shallow-skip"/>
	<xsl:mode name="html" on-no-match="shallow-skip"/>
	<xsl:param name="dir" select="'./issues'"/>
	<xsl:param name="out" select="'./tei'"/>
	
	<xsl:variable name="dir.resolved" select="resolve-uri($dir)"/>
	<xsl:variable name="out.resolved" select="resolve-uri($out)"/>
	
	<xsl:variable name="files" select="uri-collection($dir || '?select=*.json;recurse=yes')"/>

	<xsl:template name="go">
		<xsl:message select="$dir.resolved"/>
		<xsl:message select="count($files)"/>
		<xsl:for-each select="$files">
			<xsl:call-template name="makeTEI"/>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="makeTEI">
		
		<xsl:variable name="basename" 
			select="substring-after(., $dir.resolved) => replace('\.json$', '')"/>
		<xsl:result-document href="{resolve-uri($out.resolved || '/' || $basename || '.xml')}">
			
			<xsl:message select="current-output-uri()"/>
			<xsl:processing-instruction name="xml-model">href="https://jenkins.tei-c.org/job/TEIP5-CMC-features/lastSuccessfulBuild/artifact/P5/release/xml/tei/custom/schema/relaxng/tei_all.rng" schematypens="http://relaxng.org/ns/structure/1.0"</xsl:processing-instruction>
			<TEI xmlns="http://www.tei-c.org/ns/1.0">
				<teiHeader>
					<fileDesc>
						<titleStmt>
							<title>GitHub Issues</title>
						</titleStmt>
						<publicationStmt>
							<p/>
						</publicationStmt>
						<sourceDesc>
							<p>GitHub</p>
						</sourceDesc>
					</fileDesc>
					<profileDesc>
						<particDesc>
							<listPerson>
								<xsl:call-template name="participants">
									<xsl:with-param name="issues" select="json-doc(.)"/>
								</xsl:call-template>
							</listPerson>
						</particDesc>
					</profileDesc>
				</teiHeader>
				<text>
					<body>
						<xsl:for-each select="array:flatten(json-doc(.))">
							<xsl:call-template name="issue"/>
						</xsl:for-each>
					</body>
				</text>
				
			</TEI>
		</xsl:result-document>
	
		
	</xsl:template>
	
	<xsl:template name="participants">
		<xsl:param name="issues"/>
		<xsl:iterate select="array:flatten($issues)">
			<xsl:param name="people" select="map{}" as="map(*)"/>
			<xsl:on-completion>
				<xsl:for-each select="map:keys($people)">
					<xsl:sequence select="$people(.)"/>
					
				</xsl:for-each>
			</xsl:on-completion>
			<xsl:variable name="user" select=".?user" as="map(*)"/>
			<xsl:variable name="assignees" select="array:flatten(.?assignees)" as="map(*)*"/>
			<xsl:variable name="posters" select="array:flatten(.?comments) ! .?user"
				as="map(*)*"/>
			<xsl:variable name="newPeople" as="map(*)*">
				<xsl:for-each-group select="($user, $assignees, $posters)" group-by="jt:getUserID(.)">
					<xsl:if test="not(map:contains($people, current-grouping-key()))">
						<xsl:sequence select="current-group()[1]"/>
					</xsl:if>
				</xsl:for-each-group>
			</xsl:variable>
			<xsl:next-iteration>
				<xsl:with-param name="people" select="if (empty($newPeople)) then $people else
					fold-right($newPeople, $people, function($person, $array){map:put($array, jt:getUserID($person), jt:userToPerson($person))})"/>
			</xsl:next-iteration>
		</xsl:iterate>
	</xsl:template>

    <xsl:template name="issue">
    	<xsl:variable name="number" select="xs:integer(.?number)"/>
        <div type="issue" subtype="{.?state}" n="{$number}">
        	<!--Not sure how best to model "assignees"-->
        	<head><xsl:value-of select=".?title"/></head>
        	<xsl:call-template name="post">
        		<xsl:with-param name="issue_number" select="$number"/>
        	</xsl:call-template>
        	<div type="comments">
        		<xsl:for-each select="array:flatten(.?comments)">
        			<xsl:call-template name="post">
        				<xsl:with-param name="position" select="position()" as="xs:integer"/>
        				<xsl:with-param name="issue_number" select="$number"/>
        			</xsl:call-template>
        		</xsl:for-each>
        	</div>
        </div>
    </xsl:template>
	
	<xsl:template name="post">
		<xsl:param name="issue_number"/>
		<xsl:param name="position" select="()"/>
		<post xml:id="{string-join(('issue', $issue_number, $position),'_')}" ref="{.?html_url}"
			when-iso="{.?created_at}" who="#{jt:getUserID(.?user)}">
			<ab>
				<code lang="gfm">
					<xsl:value-of select="replace(.?body, '&#xD;','')"/>
				</code>
			</ab>
				<!--<xsl:apply-templates select="parse-xml-fragment(.?body_html)//*:body/*" mode="html"/>-->
			<xsl:call-template name="reactions"/>
			
		</post>
	</xsl:template>
	
	<xsl:template name="reactions">
		<xsl:variable name="reactions" select=".?reactions" as="map(*)"/>
		<xsl:where-populated>
			<trailer>
				<xsl:where-populated>
					<measureGrp>
						<xsl:sequence>
							<xsl:on-non-empty>
								<xsl:attribute name="type">reactions</xsl:attribute>
								<xsl:attribute name="corresp" select="$reactions?url"/>
							</xsl:on-non-empty>
							<xsl:for-each select="map:keys($reactions)[not(. = ('url','total_count'))]">
								<xsl:if test="$reactions(.) gt 0">
									<measure commodity="{.}" quantity="{$reactions(.)}"/>
								</xsl:if>
							</xsl:for-each>
						</xsl:sequence>
					</measureGrp>
				</xsl:where-populated>

			</trailer>
		</xsl:where-populated>
	</xsl:template>
	
	
	<xsl:template match="html:p" mode="html">
		<p>
			<xsl:apply-templates mode="#current"/>
		</p>
	</xsl:template>
	
	<xsl:template match="html:div" mode="html">
		<ab>
			<xsl:apply-templates mode="#current"/>
		</ab>
	</xsl:template>
	
	<xsl:template match="html:div[contains-token(@class,'highlight')]" mode="html">
		<ab>
			<eg>
				<xsl:apply-templates mode="#current"/>
			</eg>
		</ab>
		
	</xsl:template>
	
	<xsl:template match="html:pre[html:code]" mode="html">
		<eg>
			<xsl:apply-templates mode="#current"/>
		</eg>
	</xsl:template>
	
	<xsl:template match="html:code" mode="html">
		<code>
			<xsl:apply-templates mode="#current"/>
		</code>
	</xsl:template>
	
	<xsl:template match="text()" mode="html">
		<xsl:value-of select="."/>
	</xsl:template>
	
	<xsl:template match="html:ul | html:ol" mode="html">
		<list>
			<xsl:apply-templates mode="#current"/>
		</list>
	</xsl:template>
	
	<xsl:template match="html:li" mode="html">
		<item>
			<xsl:apply-templates mode="#current"/>
		</item>
	</xsl:template>
	
	<xsl:template match="html:blockquote" mode="html">
		<quote>
			<xsl:apply-templates mode="#current"/>
		</quote>
	</xsl:template>
	
	<xsl:template match="html:a" mode="html">
		<ref target="{@href}">
			<xsl:apply-templates mode="#current"/>
		</ref>
	</xsl:template>
	
	
	<xsl:function name="jt:userToPerson" as="element(person)">
		<xsl:param name="object" as="map(*)"/>
		<person xml:id="{jt:getUserID($object)}" n="{$object?id}" >
			<persName>
				<addName><xsl:value-of select="$object?login"/></addName>
			</persName>
			<ptr target="{$object?html_url}"/>
		</person>
	</xsl:function>
	
	<xsl:function name="jt:getUserID" as="xs:string?">
		<xsl:param name="object" as="map(*)?"/>
		<xsl:if test="exists($object)">
			<xsl:sequence select="string($object?login)"/>
		</xsl:if>
	</xsl:function>
	
	<xsl:function name="jt:isUser" as="xs:boolean">
		<xsl:param name="object" as="map(*)"/>
		<xsl:sequence select="map:contains($object, 'login') and $object?type = 'User'"/>
	</xsl:function>


</xsl:stylesheet>