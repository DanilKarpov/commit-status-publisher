<%@ include file="/include-internal.jsp" %>

<bs:page>
  <jsp:attribute name="page_title">Proxy Server Diagnostics</jsp:attribute>
  <jsp:attribute name="head_include">

  <bs:linkScript>
    /js/bs/proxyChecker.js
  </bs:linkScript>

  <script type="text/javascript">
    $j(document).ready(function () {
      BS.ProxyChecker.checkAndLoadResult($('proxyCheckProgress'), $('proxyCheckReport'));
    });

    BS.Navigation.items = [
      {title: "Proxy Server Diagnostics", selected: true}
    ];
  </script>
  </jsp:attribute>
  <jsp:attribute name="body_include">
      <div>
        Diagnostic information on HTTP proxy configuration for the current session.
      </div>
      <forms:progressRing id="proxyCheckProgress" className="progressRingInline" style="display: none;"/>
      <div id="proxyCheckReport"></div>
  </jsp:attribute>
</bs:page>




