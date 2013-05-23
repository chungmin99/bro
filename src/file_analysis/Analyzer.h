// See the file "COPYING" in the main distribution directory for copyright.

#ifndef FILE_ANALYSIS_ANALYZER_H
#define FILE_ANALYSIS_ANALYZER_H

#include "Val.h"
#include "NetVar.h"

namespace file_analysis {

typedef BifEnum::FileAnalysis::Analyzer FA_Tag;

class File;

/**
 * Base class for analyzers that can be attached to file_analysis::File objects.
 */
class Analyzer {
public:

	/**
	 * Destructor.  Nothing special about it. Virtual since we definitely expect
	 * to delete instances of derived classes via pointers to this class.
	 */
	virtual ~Analyzer()
		{
		DBG_LOG(DBG_FILE_ANALYSIS, "Destroy file analyzer %d", tag);
		Unref(args);
		}

	/**
	 * Subclasses may override this metod to receive file data non-sequentially.
	 * @param data points to start of a chunk of file data.
	 * @param len length in bytes of the chunk of data pointed to by \a data.
	 * @param offset the byte offset within full file that data chunk starts.
	 * @return true if the analyzer is still in a valid state to continue
	 *         receiving data/events or false if it's essentially "done".
	 */
	virtual bool DeliverChunk(const u_char* data, uint64 len, uint64 offset)
		{ return true; }

	/**
	 * Subclasses may override this method to receive file sequentially.
	 * @param data points to start of the next chunk of file data.
	 * @param len length in bytes of the chunk of data pointed to by \a data.
	 * @return true if the analyzer is still in a valid state to continue
	 *         receiving data/events or false if it's essentially "done".
	 */
	virtual bool DeliverStream(const u_char* data, uint64 len)
		{ return true; }

	/**
	 * Subclasses may override this method to specifically handle an EOF signal,
	 * which means no more data is going to be incoming and the analyzer
	 * may be deleted/cleaned up soon.
	 * @return true if the analyzer is still in a valid state to continue
	 *         receiving data/events or false if it's essentially "done".
	 */
	virtual bool EndOfFile()
		{ return true; }

	/**
	 * Subclasses may override this method to handle missing data in a file.
	 * @param offset the byte offset within full file at which the missing
	 *        data chunk occurs.
	 * @param len the number of missing bytes.
	 * @return true if the analyzer is still in a valid state to continue
	 *         receiving data/events or false if it's essentially "done".
	 */
	virtual bool Undelivered(uint64 offset, uint64 len)
		{ return true; }

	/**
	 * @return the analyzer type enum value.
	 */
	FA_Tag Tag() const { return tag; }

	/**
	 * @return the AnalyzerArgs associated with the analyzer.
	 */
	RecordVal* Args() const { return args; }

	/**
	 * @return the file_analysis::File object to which the analyzer is attached.
	 */
	File* GetFile() const { return file; }

	/**
	 * Retrieves an analyzer tag field from full analyzer argument record.
	 * @param args an \c AnalyzerArgs (script-layer type) value.
	 * @return the analyzer tag equivalent of the 'tag' field from the
	 *         \c AnalyzerArgs value \a args.
	 */
	static FA_Tag ArgsTag(const RecordVal* args)
		{
		using BifType::Record::FileAnalysis::AnalyzerArgs;
		return static_cast<FA_Tag>(
		              args->Lookup(AnalyzerArgs->FieldOffset("tag"))->AsEnum());
		}

protected:

	/**
	 * Constructor.  Only derived classes are meant to be instantiated.
	 * @param arg_args an \c AnalyzerArgs (script-layer type) value specifiying
	 *        tunable options, if any, related to a particular analyzer type.
	 * @param arg_file the file to which the the analyzer is being attached.
	 */
	Analyzer(RecordVal* arg_args, File* arg_file)
	    : tag(file_analysis::Analyzer::ArgsTag(arg_args)),
	      args(arg_args->Ref()->AsRecordVal()),
	      file(arg_file)
		{}

private:

	FA_Tag tag; /**< The particular analyzer type of the analyzer instance. */
	RecordVal* args; /**< \c AnalyzerArgs val gives tunable analyzer params. */
	File* file; /**< The file to which the analyzer is attached. */
};

typedef file_analysis::Analyzer* (*AnalyzerInstantiator)(RecordVal* args,
                                                         File* file);

} // namespace file_analysis

#endif
